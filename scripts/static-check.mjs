#!/usr/bin/env node
/**
 * 静态一致性检查（不编译也能跑）
 *
 * 为什么要有它：iOS 只能靠 macOS 编译，而 GitHub Actions 的 macOS 分钟是有限资源
 * （私有仓库约 200 分钟/月）。把"结构类错误"提前在免费的 ubuntu runner 上拦掉，
 * 能省掉大量"推上去 → 等 3 分钟 → 发现是新文件没加进 pbxproj"的循环。
 *
 * 用法：
 *   node scripts/static-check.mjs            # 常规检查；已知缺口只警告
 *   node scripts/static-check.mjs --strict   # Phase 1 完成后使用；已知缺口也判失败
 * 退出码：0 = 通过，1 = 有失败项
 */
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs'
import { dirname, join, relative, sep } from 'node:path'
import { fileURLToPath } from 'node:url'

const HERE = dirname(fileURLToPath(import.meta.url))
const ROOT = join(HERE, '..')            // ios/
const APP = join(ROOT, 'Yimengqian')     // ios/Yimengqian/
const SRC = join(APP, 'Yimengqian')      // ios/Yimengqian/Yimengqian/（源码根）
const STRICT = process.argv.includes('--strict')

const rows = []
const ok = (id, msg) => rows.push({ id, level: 'PASS', msg })
const bad = (id, msg) => rows.push({ id, level: 'FAIL', msg })
const warn = (id, msg) => rows.push({ id, level: 'WARN', msg })

function walk(dir, out = []) {
  for (const name of readdirSync(dir)) {
    if (name === '.DS_Store') continue
    const p = join(dir, name)
    if (statSync(p).isDirectory()) walk(p, out)
    else out.push(p)
  }
  return out
}
const rel = (p) => relative(ROOT, p).split(sep).join('/')
const read = (p) => readFileSync(p, 'utf8')
// 去掉行注释再做"代码级"断言：否则修完 bug 后，注释里留下的旧值/旧路径会被误判成仍未修
const stripComments = (src) => src.replace(/\/\/[^\n]*/g, '')

// ── 1. .swift 双射：磁盘上的源码 ⇄ pbxproj 里参与编译的文件 ────────────────
// 这是最容易踩的坑：新增 AI/*.swift 却没加进 Sources 阶段 → 本地"看起来在"，
// 编译时符号找不到，而 Xcode 14.2 的 pbxproj 又是自动生成的、容易忘。
const PBX = join(APP, 'Yimengqian.xcodeproj', 'project.pbxproj')
const SCHEME = join(APP, 'Yimengqian.xcodeproj', 'xcshareddata', 'xcschemes', 'Yimengqian.xcscheme')
if (!existsSync(PBX)) {
  bad('pbxproj', '找不到 project.pbxproj')
} else {
  const pbx = read(PBX)
  const compiled = new Set(
    [...pbx.matchAll(/\/\*\s*([^\s*]+\.swift)\s+in Sources\s*\*\//g)].map((m) => m[1])
  )
  const onDisk = new Set(
    walk(SRC).filter((p) => p.endsWith('.swift')).map((p) => rel(p).split('/').pop())
  )
  const notCompiled = [...onDisk].filter((f) => !compiled.has(f))
  const notOnDisk = [...compiled].filter((f) => !onDisk.has(f))

  if (notCompiled.length) bad('pbxproj.sources', `磁盘有但没进 Sources（编译会找不到符号）：${notCompiled.join(', ')}`)
  if (notOnDisk.length) bad('pbxproj.sources', `pbxproj 引用了不存在的文件：${notOnDisk.join(', ')}`)
  if (!notCompiled.length && !notOnDisk.length) ok('pbxproj.sources', `${compiled.size} 个 .swift 与 pbxproj 完全一致`)

  if (/objectVersion = 56;/m.test(pbx)) ok('pbxproj.objectVersion', 'objectVersion = 56（Xcode 14 格式，Xcode 16 可读）')
  else warn('pbxproj.objectVersion', 'objectVersion 不是 56，格式可能被改动过')

  if (existsSync(SCHEME)) ok('scheme', '共享 scheme 存在')
  else bad('scheme', '缺少 xcshareddata/xcschemes/Yimengqian.xcscheme（CI 无法 xcodebuild）')

  // ── pbxproj 引用完整性 ──
  // 手改 pbxproj（新增文件 / 调整资源）最容易出的错是：ID 拼错、或加了 buildFile
  // 却忘了在 fileRef 里定义。这类错在 Xcode 里表现为莫名其妙的「找不到文件」。
  const fileRefIds = new Set(
    [...pbx.matchAll(/^\t\t([0-9A-F]{24}) \/\*[^*]*\*\/ = \{isa = PBXFileReference;/gm)].map((m) => m[1])
  )
  const buildFileIds = new Set(
    [...pbx.matchAll(/^\t\t([0-9A-F]{24}) \/\*[^*]*\*\/ = \{isa = PBXBuildFile;/gm)].map((m) => m[1])
  )
  const fileRefTargets = [...pbx.matchAll(/isa = PBXBuildFile;[^}]*?fileRef = ([0-9A-F]{24})/g)].map((m) => m[1])
  const danglingRefs = fileRefTargets.filter((r) => !fileRefIds.has(r))

  const phaseRefs = []
  for (const m of pbx.matchAll(/isa = PBX(Sources|Resources|Frameworks)BuildPhase;[\s\S]*?files = \(([\s\S]*?)\);/g)) {
    for (const idm of m[2].matchAll(/([0-9A-F]{24})/g)) phaseRefs.push({ id: idm[0], phase: m[1] })
  }
  const danglingPhase = phaseRefs.filter((p) => !buildFileIds.has(p.id)).map((p) => `${p.phase}:${p.id}`)

  if (danglingRefs.length) bad('pbxproj.refs', `PBXBuildFile 指向了未定义的 fileRef：${danglingRefs.join(', ')}`)
  else if (danglingPhase.length) bad('pbxproj.refs', `构建阶段引用了未定义的 buildFile：${danglingPhase.join(', ')}`)
  else ok('pbxproj.refs', `引用完整：${buildFileIds.size} 个 buildFile / ${fileRefIds.size} 个 fileRef，无悬空 ID`)

  // 资源：真正进包的应该只有 Screens 文件夹（Reference 是死资源，不应打包）
  const folderRefs = [...pbx.matchAll(/isa = PBXFileReference; lastKnownFileType = folder;[^}]*?path = "?([^";]+)"?;/g)].map((m) => m[1])
  if (folderRefs.some((p) => p === 'Content')) bad('pbxproj.bundle', '仍以 Content/ 整目录打包（会把 Reference 的 55.7 MB 带进 App）')
  else if (folderRefs.some((p) => p.includes('Screens'))) ok('pbxproj.bundle', `设计稿以文件夹引用打包：${folderRefs.join(', ')}`)
  else bad('pbxproj.bundle', '没有找到 Screens 文件夹引用，App 会缺全部设计稿')

  if (!/PrivacyInfo\.xcprivacy/.test(pbx)) warn('pbxproj.privacy', 'PrivacyInfo.xcprivacy 未加入工程')
  else ok('pbxproj.privacy', 'PrivacyInfo.xcprivacy 已加入 Resources 阶段')
}

// ── 2. 25 屏配置：图片引用 / 路由闭合 / 热区坐标 ────────────────────────────
const CFG_PATH = join(SRC, 'Config', 'ScreensConfig.swift')
const cfg = read(CFG_PATH)
const CONTENT = join(SRC, 'Content')

const imgRefs = [...cfg.matchAll(/image:\s*"([^"]+\.png)"/g)].map((m) => m[1])
const missingImgs = imgRefs.filter((ref) => !existsSync(join(CONTENT, ref)))
if (missingImgs.length) bad('screens.images', `图片引用不存在：${missingImgs.join(', ')}`)
else ok('screens.images', `${imgRefs.length} 处 image 引用全部命中 Content/ 下的真实文件`)

const screens = [...cfg.matchAll(/ScreenConfig\(id:\s*"([^"]+)",\s*route:\s*"([^"]+)"/g)].map((m) => ({ id: m[1], route: m[2] }))
const hotspots = [...cfg.matchAll(/Hotspot\(id:\s*"([^"]+)"/g)].length
if (screens.length === 25) ok('screens.count', `25 屏（热区 ${hotspots} 个）`)
else bad('screens.count', `期望 25 屏，实际 ${screens.length} 屏`)

const routes = new Set(screens.map((s) => s.route))
const dupRoutes = screens.map((s) => s.route).filter((r, i, a) => a.indexOf(r) !== i)
if (dupRoutes.length) bad('screens.routes', `route 重复：${[...new Set(dupRoutes)].join(', ')}`)
else ok('screens.routes', `${routes.size} 条 route 无重复`)

const targets = [...new Set([...cfg.matchAll(/target:\s*"([^"]+)"/g)].map((m) => m[1]))]
const dangling = targets.filter((t) => !routes.has(t))
if (dangling.length) bad('screens.targets', `跳转目标不存在对应屏：${dangling.join(', ')}`)
else ok('screens.targets', `${targets.length} 个跳转目标全部能解析到已定义 route`)

const screensDir = join(CONTENT, 'Screens')
const pngOnDisk = existsSync(screensDir) ? readdirSync(screensDir).filter((f) => f.endsWith('.png')) : []
const referenced = new Set(imgRefs.map((r) => r.replace(/^.*\//, '')))
const orphans = pngOnDisk.filter((f) => !referenced.has(f))
if (pngOnDisk.length !== 25) bad('content.screens', `Content/Screens 下应有 25 张，实际 ${pngOnDisk.length} 张`)
else if (orphans.length) warn('content.screens', `有未被任何屏引用的设计稿：${orphans.join(', ')}`)
else ok('content.screens', '25 张设计稿全部被引用，无游离文件')

// ── 2b. 内容层配图：引用要能落到磁盘，且所在目录要挂进工程 ──────────────────
// 这两条都是「不报错但白屏」的坑：
//   ① 文件名打错 → UIImage 返回 nil，页面上是一片空白；
//   ② 目录没加进 pbxproj 的 Resources → 文件在磁盘上，但不在 .app 里。
const CD_PATH = join(SRC, 'Models', 'ContentData.swift')
if (existsSync(CD_PATH)) {
  const cdSrc = stripComments(read(CD_PATH))
  const cdRefs = [...cdSrc.matchAll(/image:\s*"([^"]+)"/g)].map((m) => m[1]).filter(Boolean)
  const uniq = [...new Set(cdRefs)]
  const missingArt = uniq.filter((r) => !existsSync(join(CONTENT, r)))
  if (missingArt.length) bad('content.images', `ContentData 引用了不存在的图：${missingArt.join(', ')}`)
  else ok('content.images', `${uniq.length} 个内容配图引用全部命中 Content/ 下的真实文件`)

  const pbxSrc = existsSync(PBX) ? read(PBX) : ''
  const folderPaths = [...pbxSrc.matchAll(/isa = PBXFileReference; lastKnownFileType = folder; path = "?([^";]+)"?;/g)].map((m) => m[1])
  const usedDirs = [...new Set(uniq.map((r) => r.split('/')[0]))]
  const notBundled = usedDirs.filter((d) => !folderPaths.some((p) => p === d || p.endsWith('/' + d)))
  if (notBundled.length) bad('content.bundle', `这些素材目录没加进工程 Resources，不会进包：${notBundled.join(', ')}`)
  else ok('content.bundle', `素材目录均已以文件夹引用进包：${usedDirs.join(', ')}`)
}

// ── 3. Info.plist 关键键（权限声明会随 AI 能力增加，届时在此扩展）──────────
const PLIST = join(SRC, 'Info.plist')
if (!existsSync(PLIST)) bad('plist', '找不到 Info.plist')
else {
  const plist = read(PLIST)
  const keys = ['CFBundleDisplayName', 'UILaunchScreen', 'UISupportedInterfaceOrientations']
  const lost = keys.filter((k) => !plist.includes(`<key>${k}</key>`))
  if (lost.length) bad('plist', `Info.plist 缺少键：${lost.join(', ')}`)
  else ok('plist', 'Info.plist 关键键齐全')
  if (!/一梦千年/.test(plist)) warn('plist.displayName', 'CFBundleDisplayName 不是「一梦千年」')
}

// ── 4. 已知缺口（Phase 1 修完后改用 --strict，届时会变红）──────────────────
const KNOWN = []
const push = (id, msg) => KNOWN.push({ id, msg })

const hotspotView = stripComments(read(join(SRC, 'Views', 'HotspotScreenView.swift')))
if (/return\s+0\.4617/.test(hotspotView)) push('P1-1', '回退常数 0.4617 写反（应 2.1667 或 1846.0/852.0）')
const x100 = [...cfg.matchAll(/Hotspot\(id:\s*"([^"]+)"[^)]*x:\s*100(\.0*)?,/g)].map((m) => m[1])
if (x100.length) push('P1-2', `${x100.length} 个热区 x=100 整体越界不可点：${x100.join(', ')}`)

const swiftFiles = walk(SRC).filter((p) => p.endsWith('.swift'))
const refHits = []
for (const f of swiftFiles) {
  const n = (stripComments(read(f)).match(/Reference\//g) || []).length
  if (n) refHits.push(`${rel(f)}×${n}`)
}
if (refHits.length) push('P1-3', `ContentData 仍引用错配的 Reference/ 资源：${refHits.join(', ')}`)

const keysFile = read(join(SRC, 'Config', 'StorageKeys.swift'))
if (!keysFile.includes('sushiVoicePlaying')) push('P1-2', 'StorageKeys 未登记 sushiVoicePlaying（resetAll 清不掉）')

const navIds = [...new Set([...cfg.matchAll(/Hotspot\(id:\s*"(bottom-[a-z-]+)"/g)].map((m) => m[1]))]
const navDup = navIds.filter((id) => id === 'bottom-activity' || id === 'bottom-activities')
if (navDup.length > 1) push('P2-5', `底栏 id 命名冲突：${navDup.join(' / ')} 并存`)

// ── iOS 侧修正层的一致性 ──────────────────────────────────────────────────
// tools/hotspot-overrides.ios.json 与 hotspot-deletions.json 是按「屏 id / 热区 id」
// 引用的。若 screens.ts 改了 id（或热区被删），这两份文件会变成悬空引用 ——
// 生成器不会报错，只是那条修正静默失效。这里提前拦掉。
const OV_IOS = join(ROOT, 'tools', 'hotspot-overrides.ios.json')
const DEL_IOS = join(ROOT, 'tools', 'hotspot-deletions.json')
if (existsSync(OV_IOS) || existsSync(DEL_IOS)) {
  const readJson = (p) => (existsSync(p) ? JSON.parse(read(p)) : {})
  const screenIds = new Set(screens.map((s) => s.id))
  const hsIdsBy = new Map()
  for (const m of cfg.matchAll(/ScreenConfig\(id:\s*"([^"]+)"[\s\S]*?hotspots:\s*\[([\s\S]*?)\n            \]\)/g)) {
    hsIdsBy.set(m[1], new Set([...m[2].matchAll(/Hotspot\(id:\s*"([^"]+)"/g)].map((x) => x[1])))
  }
  const danglingO = []
  const danglingD = []
  let nO = 0
  let nD = 0
  try {
    for (const [sid, hs] of Object.entries(readJson(OV_IOS))) {
      if (!screenIds.has(sid)) { danglingO.push(`屏 ${sid} 不存在`); continue }
      for (const hid of Object.keys(hs)) {
        nO++
        if (!hsIdsBy.get(sid)?.has(hid)) danglingO.push(`${sid}/${hid}`)
      }
    }
    for (const [sid, ids] of Object.entries(readJson(DEL_IOS))) {
      // 删除清单本就引用「已被删掉」的热区，所以只校验屏 id，不校验热区 id（保证可重复执行）
      if (!screenIds.has(sid)) { danglingD.push(`屏 ${sid} 不存在`); continue }
      for (const hid of ids) nD++
    }
  } catch (e) {
    bad('hotspot.ios', `iOS 侧修正文件无法解析：${e.message}`)
  }
  if (danglingO.length) bad('hotspot.ios', `hotspot-overrides.ios.json 引用了不存在的热区：${danglingO.join(', ')}`)
  else if (danglingD.length) bad('hotspot.ios', `hotspot-deletions.json 引用了不存在的热区：${danglingD.join(', ')}`)
  else ok('hotspot.ios', `iOS 侧修正 ${nO} 条坐标 / ${nD} 条删除，引用全部有效`)
}

if (KNOWN.length) {
  for (const k of KNOWN) (STRICT ? bad : warn)(`known.${k.id}`, k.msg)
} else {
  ok('known', '已知缺口全部清零')
}

// ── 汇总 ────────────────────────────────────────────────────────────────
const pad = (s, n) => s + ' '.repeat(Math.max(0, n - [...s].length))
console.log('\n一梦千年 · iOS 静态一致性检查' + (STRICT ? '（strict）' : ''))
console.log('─'.repeat(72))
for (const r of rows) {
  const tag = r.level === 'PASS' ? '✔' : r.level === 'WARN' ? '▲' : '✘'
  console.log(`${tag} ${pad(r.id, 22)} ${r.msg}`)
  if (r.level === 'FAIL' && process.env.GITHUB_ACTIONS) console.log(`::error title=${r.id}::${r.msg}`)
}
const failed = rows.filter((r) => r.level === 'FAIL').length
const warned = rows.filter((r) => r.level === 'WARN').length
console.log('─'.repeat(72))
console.log(`通过 ${rows.filter((r) => r.level === 'PASS').length} · 警告 ${warned} · 失败 ${failed}`)
if (warned && !STRICT) {
  console.log('\n提示：▲ 是「已知缺口」（Phase 1 的待修项）。修完后用 --strict 运行，它们会变成失败项，\n      从而防止修复被悄悄回退。')
}
process.exit(failed ? 1 : 0)
