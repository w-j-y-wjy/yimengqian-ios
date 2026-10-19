#!/usr/bin/env node
/**
 * 本地预览器生成器（Windows 可用，不需要 Mac、不需要 Xcode）
 *
 * 为什么需要它：iOS 只能靠 Xcode 编译，而这台是 Windows 机器；
 * GitHub Actions 的模拟器是「一次性虚拟机 + 文件出口」，没法登进去点。
 * 但这个工程是「整屏设计稿 PNG + 百分比热区」，热区配置全在 ScreensConfig.swift 里 ——
 * 那么把同一份配置搬到浏览器里，就能在本机把 25 屏、323 个热区全部点一遍。
 *
 * 它验证什么：跳转目标对不对、热区位置偏没偏、点了有没有反应、选中态标在哪。
 * 它不验证什么：系统级行为（键盘、支付、相机、真机手感）——那些只能真机或模拟器。
 *
 * 用法：
 *   node tools/preview.mjs           # 重新生成 preview/index.html
 *   node tools/preview.mjs --open    # 生成后直接用默认浏览器打开
 */
import { readFileSync, writeFileSync, existsSync, mkdirSync, openSync, readSync, closeSync } from 'node:fs'
import { dirname, join, basename } from 'node:path'
import { fileURLToPath } from 'node:url'
import { execFileSync } from 'node:child_process'

const HERE = dirname(fileURLToPath(import.meta.url))
const ROOT = join(HERE, '..')
const SRC = join(ROOT, 'Yimengqian', 'Yimengqian')
const CFG = join(SRC, 'Config', 'ScreensConfig.swift')
const KEYS = join(SRC, 'Config', 'StorageKeys.swift')
const SELECTION = join(SRC, 'Engine', 'SelectionStore.swift')
const SHOTS = join(SRC, 'Content', 'Screens')
const OUT_DIR = join(ROOT, 'preview')
const OUT = join(OUT_DIR, 'index.html')

// ── Swift 迷你解析器 ────────────────────────────────────────────────────────
// 只针对「自动生成的配置文件」这种高度规整的输入，不追求通用 Swift 解析。
// 行注释按「整行以 // 开头」剔除，避免把字符串里的 / 误伤。

const stripLineComments = (s) =>
  s.split('\n').map((l) => (/^\s*\/\//.test(l) ? '' : l)).join('\n')

/** 从 '(' 的位置开始配对括号，返回括号内的文本（跳过字符串字面量里的括号） */
function findCallBody(src, openIdx) {
  let depth = 0
  let inStr = false
  for (let i = openIdx; i < src.length; i++) {
    const ch = src[i]
    if (inStr) {
      if (ch === '\\') { i++; continue }
      if (ch === '"') inStr = false
      continue
    }
    if (ch === '"') { inStr = true; continue }
    if (ch === '(') depth++
    else if (ch === ')') {
      depth--
      if (depth === 0) return { body: src.slice(openIdx + 1, i), end: i }
    }
  }
  throw new Error(`括号不配对（起点 ${openIdx}）`)
}

/** 按顶层逗号切分：括号/方括号内的逗号不动 */
function splitTopLevel(s) {
  const out = []
  let depth = 0
  let inStr = false
  let cur = ''
  for (let i = 0; i < s.length; i++) {
    const ch = s[i]
    if (inStr) {
      cur += ch
      if (ch === '\\') { cur += s[++i] ?? ''; continue }
      if (ch === '"') inStr = false
      continue
    }
    if (ch === '"') { inStr = true; cur += ch; continue }
    if (ch === '(' || ch === '[' || ch === '{') depth++
    if (ch === ')' || ch === ']' || ch === '}') depth--
    if (ch === ',' && depth === 0) { out.push(cur.trim()); cur = ''; continue }
    cur += ch
  }
  if (cur.trim()) out.push(cur.trim())
  return out
}

function parseValue(raw) {
  const v = raw.trim()
  if (v.startsWith('"')) {
    try { return JSON.parse(v) } catch { return v.slice(1, -1) }
  }
  if (v.startsWith('.')) return v.slice(1)                 // .navigate → "navigate"
  if (v.startsWith('[')) {
    const inner = v.slice(1, v.lastIndexOf(']'))
    return splitTopLevel(inner).filter(Boolean).map(parseKV)
  }
  const n = Number(v)
  return Number.isNaN(n) ? v : n
}

function parseKV(item) {
  const m = item.match(/^KV\(([\s\S]*)\)$/)
  const body = m ? m[1] : item
  const o = {}
  for (const part of splitTopLevel(body)) {
    const i = part.indexOf(':')
    if (i < 0) continue
    o[part.slice(0, i).trim()] = parseValue(part.slice(i + 1))
  }
  return o
}

function parseFields(body) {
  const out = {}
  for (const part of splitTopLevel(body)) {
    const i = part.indexOf(':')
    if (i < 0) continue
    out[part.slice(0, i).trim()] = part.slice(i + 1).trim()
  }
  return out
}

function parseAction(raw) {
  const m = raw.match(/^HotspotAction\(([\s\S]*)\)$/)
  if (!m) throw new Error(`无法解析动作：${raw.slice(0, 60)}`)
  const a = {}
  for (const [k, v] of Object.entries(parseFields(m[1]))) a[k] = parseValue(v)
  return a
}

function parseHotspot(raw) {
  const m = raw.match(/^Hotspot\(([\s\S]*)\)$/)
  if (!m) throw new Error(`无法解析热区：${raw.slice(0, 60)}`)
  const h = {}
  for (const [k, v] of Object.entries(parseFields(m[1]))) {
    h[k] = k === 'action' ? parseAction(v) : parseValue(v)
  }
  return h
}

// ── 解析 ScreensConfig.swift ───────────────────────────────────────────────
const cfgSrc = stripLineComments(readFileSync(CFG, 'utf8'))
const screens = []
const reScreen = /ScreenConfig\(/g
let m
while ((m = reScreen.exec(cfgSrc))) {
  const { body, end } = findCallBody(cfgSrc, m.index + 'ScreenConfig'.length)
  const f = parseFields(body)
  const id = parseValue(f.id)
  const route = parseValue(f.route)
  const image = parseValue(f.image)
  const hsRaw = f.hotspots
  const inner = hsRaw.slice(hsRaw.indexOf('[') + 1, hsRaw.lastIndexOf(']'))
  const hotspots = splitTopLevel(inner).filter(Boolean).map(parseHotspot)
  screens.push({ id, route, image: basename(image), hotspots })
  reScreen.lastIndex = end
}

if (screens.length !== 25) throw new Error(`期望 25 屏，解析到 ${screens.length} 屏`)

// ── 解析 StorageKeys（名字 → 字面量）───────────────────────────────────────
const keysSrc = readFileSync(KEYS, 'utf8')
const keyMap = {}
for (const km of keysSrc.matchAll(/static let (\w+)\s*=\s*"([^"]*)"/g)) keyMap[km[1]] = km[2]

function resolveKeyList(swift, regex) {
  const hit = swift.match(regex)
  if (!hit) return []
  const out = []
  for (const km of hit[1].matchAll(/StorageKeys\.(\w+)/g)) {
    const v = keyMap[km[1]]
    if (v != null) out.push(v)
  }
  return out
}
const selSrc = readFileSync(SELECTION, 'utf8')
const trackedKeys = resolveKeyList(selSrc, /static let trackedKeys[^=]*=\s*\[([\s\S]*?)\n    \]/)
const visuallyRepresentedKeys = resolveKeyList(
  selSrc,
  /static let visuallyRepresentedKeys[^=]*=\s*\[([\s\S]*?)\n    \]/
)

// ── 设计稿真实尺寸（只读 PNG 头 24 字节，不把图片读进内存）─────────────────
function pngSize(p) {
  const fd = openSync(p, 'r')
  const buf = Buffer.alloc(24)
  readSync(fd, buf, 0, 24, 0)
  closeSync(fd)
  if (buf.readUInt32BE(12) !== 0x49484452) throw new Error(`不是 PNG：${p}`)
  return { w: buf.readUInt32BE(16), h: buf.readUInt32BE(20) }
}

const missing = []
for (const s of screens) {
  const p = join(SHOTS, s.image)
  if (!existsSync(p)) { missing.push(s.image); s.w = 852; s.h = 1846; continue }
  const { w, h } = pngSize(p)
  s.w = w
  s.h = h
}
if (missing.length) console.warn(`⚠ 缺图（预览会显示占位）：${missing.join(', ')}`)

// ── 结构诊断（生成期就算一遍，写进控制台；页面里还会算一次给交互用）─────────
const routes = new Set(screens.map((s) => s.route))
const issues = []
// 行为签名：类型 + 目标 + 写入键值。两个热区签名相同 = 点哪个都一样，嵌套无害。
const signature = (a) => [a.type, a.target || '', a.storageKey || '', a.storageValue || '', a.message || ''].join('|')
for (const s of screens) {
  const seen = new Set()
  for (const h of s.hotspots) {
    if (seen.has(h.id)) issues.push(`${s.id}：热区 id 重复 ${h.id}`)
    seen.add(h.id)
    if (h.x + h.width > 100.01 || h.y + h.height > 100.01) {
      issues.push(`${s.id}/${h.id}：越界 x+w=${(h.x + h.width).toFixed(2)} y+h=${(h.y + h.height).toFixed(2)}`)
    }
    if (h.width <= 0 || h.height <= 0) issues.push(`${s.id}/${h.id}：尺寸为零`)
    if (h.action.target && !routes.has(h.action.target)) {
      issues.push(`${s.id}/${h.id}：跳转目标不存在 ${h.action.target}`)
    }
  }
  // 重叠：交叠面积超过较小热区的 35% → 两个热区互抢点击。
  // 例外：外层卡片和内层按钮本来就该嵌套（如 daily-card 包着 enter-poetry），
  // 只要两者去的是同一个地方就不算问题 —— 判「行为签名」是否一致。
  for (let i = 0; i < s.hotspots.length; i++) {
    for (let j = i + 1; j < s.hotspots.length; j++) {
      const a = s.hotspots[i], b = s.hotspots[j]
      const ix = Math.max(0, Math.min(a.x + a.width, b.x + b.width) - Math.max(a.x, b.x))
      const iy = Math.max(0, Math.min(a.y + a.height, b.y + b.height) - Math.max(a.y, b.y))
      const inter = ix * iy
      if (inter <= 0) continue
      const minArea = Math.min(a.width * a.height, b.width * b.height)
      if (!(minArea > 0 && inter / minArea > 0.35)) continue
      if (signature(a.action) === signature(b.action)) continue
      issues.push(`${s.id}：热区重叠但行为不同 ${a.id} ↔ ${b.id}`)
    }
  }
}

const hotspotTotal = screens.reduce((n, s) => n + s.hotspots.length, 0)

// ── 生成 index.html ────────────────────────────────────────────────────────
if (!existsSync(OUT_DIR)) mkdirSync(OUT_DIR, { recursive: true })

const payload = {
  generatedAt: new Date().toISOString(),
  source: 'Yimengqian/Yimengqian/Config/ScreensConfig.swift',
  startScreen: 'splash',
  imgBase: '../Yimengqian/Yimengqian/Content/Screens/',
  trackedKeys,
  visuallyRepresentedKeys,
  screens
}

const json = JSON.stringify(payload).replace(/</g, '\\u003c')

const html = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>一梦千年 · 本地预览</title>
<link rel="stylesheet" href="app.css">
</head>
<body>
<div id="app">
  <aside id="sidebar">
    <div class="brand">
      <div class="brand-title">一梦千年</div>
      <div class="brand-sub">本地预览 · 热区自检</div>
    </div>
    <div class="side-stats" id="side-stats"></div>
    <div class="side-head">屏幕（<span id="screen-count">25</span>）</div>
    <div id="screen-list"></div>
  </aside>

  <main id="center">
    <div id="toolbar">
      <button id="btn-rects" class="btn" type="button">显示热区</button>
      <button id="btn-reset" class="btn btn-ghost" type="button">重置数据</button>
      <span class="spacer"></span>
      <span id="cur-label" class="cur-label"></span>
    </div>
    <div id="phone-wrap">
      <div id="phone">
        <img id="shot" alt="">
        <div id="hotspots"></div>
        <div id="marks"></div>
        <div id="toast" class="toast hidden"></div>
      </div>
    </div>
    <div id="hint">悬停看热区标签 · 点击执行动作 · ← 返回上一屏</div>
  </main>

  <aside id="inspector">
    <section><h3>当前屏</h3><div id="cur-info" class="kv"></div></section>
    <section><h3>路径</h3><div id="crumb"></div></section>
    <section><h3>本屏诊断</h3><div id="diag"></div></section>
    <section><h3>存储（点击可清空单键）</h3><div id="store"></div></section>
    <section><h3>操作记录</h3><div id="log"></div></section>
  </aside>
</div>
<script id="screen-data" type="application/json">${json}</script>
<script src="app.js"></script>
</body>
</html>
`

writeFileSync(OUT, html, 'utf8')

// ── 控制台输出 ────────────────────────────────────────────────────────────
console.log('\n一梦千年 · 本地预览器')
console.log('─'.repeat(60))
console.log(`屏幕 ${screens.length} · 热区 ${hotspotTotal} · 选择态键 ${trackedKeys.length} · 已画叠层 ${visuallyRepresentedKeys.length}`)
console.log(`尺寸样例：${screens[0].image} ${screens[0].w}×${screens[0].h}`)
if (issues.length) {
  console.log(`\n▲ 结构诊断 ${issues.length} 条：`)
  for (const i of issues) console.log('  - ' + i)
} else {
  console.log('\n✔ 结构诊断：0 条（无越界 / 无重复 id / 目标全部可解析）')
}
console.log(`\n已生成：preview/index.html（${(html.length / 1024).toFixed(0)} KB，含内联配置）`)

if (process.argv.includes('--open')) {
  const p = OUT.replace(/\\/g, '/')
  execFileSync('cmd', ['/c', 'start', '', 'file:///' + p], { stdio: 'ignore' })
  console.log('已在默认浏览器打开。')
}
