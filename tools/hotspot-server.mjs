#!/usr/bin/env node
/**
 * 热区编辑器 · 本地服务
 *
 * 为什么需要一个小服务：浏览器没有权限写磁盘，而热区坐标必须落进仓库才叫「改好了」。
 * 所以由这个脚本起一个只监听 127.0.0.1 的本地服务，页面拖完点保存 → 服务写 JSON → 重新生成 Swift。
 *
 * 用法：
 *   node tools/hotspot-server.mjs          # 起服务并自动打开浏览器
 *   node tools/hotspot-server.mjs --no-open
 *
 * 安全：只绑 127.0.0.1，不接受外部连接；写盘范围只有 tools/ 下那两个 JSON。
 * 回滚：两个文件都在 git 里，改坏了 git checkout 即可。
 */
import { createServer } from 'node:http'
import { readFileSync, writeFileSync, existsSync, statSync } from 'node:fs'
import { join, normalize, extname, sep } from 'node:path'
import { fileURLToPath } from 'node:url'
import { execFileSync } from 'node:child_process'

const ROOT = fileURLToPath(new URL('..', import.meta.url)) // ios/
const OVERRIDES = join(ROOT, 'tools', 'hotspot-overrides.ios.json')
const DELETIONS = join(ROOT, 'tools', 'hotspot-deletions.json')
const PORT = Number(process.env.PORT || 7788)

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml'
}

function readJson(p) {
  try { return existsSync(p) ? JSON.parse(readFileSync(p, 'utf8')) : {} } catch { return {} }
}

function mergeDeep(base, patch) {
  for (const [k, v] of Object.entries(patch)) {
    if (v && typeof v === 'object' && !Array.isArray(v)) {
      base[k] = base[k] && typeof base[k] === 'object' && !Array.isArray(base[k]) ? base[k] : {}
      mergeDeep(base[k], v)
    } else {
      base[k] = v
    }
  }
  return base
}

function run(cmdArgs) {
  return execFileSync(process.execPath, cmdArgs, { cwd: ROOT, encoding: 'utf8', stdio: 'pipe' })
}

function sendJson(res, code, obj) {
  res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8' })
  res.end(JSON.stringify(obj))
}

const server = createServer((req, res) => {
  const url = decodeURIComponent((req.url || '/').split('?')[0])

  // ── 保存接口 ────────────────────────────────────────────────────────────
  if (url === '/api/save') {
    if (req.method !== 'POST') return sendJson(res, 405, { ok: false, error: '只接受 POST' })
    let raw = ''
    req.on('data', (c) => { raw += c; if (raw.length > 2e6) req.destroy() })
    req.on('end', () => {
      let body
      try { body = JSON.parse(raw || '{}') } catch { return sendJson(res, 400, { ok: false, error: 'JSON 解析失败' }) }

      const touched = Object.keys(body.overrides || {}).length + Object.keys(body.deletions || {}).length
      if (!touched) return sendJson(res, 400, { ok: false, error: '没有改动' })

      try {
        if (body.overrides && Object.keys(body.overrides).length) {
          const cur = readJson(OVERRIDES)
          mergeDeep(cur, body.overrides)
          writeFileSync(OVERRIDES, JSON.stringify(cur, null, 2) + '\n')
        }
        if (body.deletions && Object.keys(body.deletions).length) {
          const cur = readJson(DELETIONS)
          for (const [sid, ids] of Object.entries(body.deletions)) {
            const set = new Set(cur[sid] || [])
            ids.forEach((id) => set.add(id))
            cur[sid] = [...set]
          }
          writeFileSync(DELETIONS, JSON.stringify(cur, null, 2) + '\n')
        }

        const log1 = run(['tools/generate_screens_swift.mjs'])
        const log2 = run(['tools/preview.mjs'])
        return sendJson(res, 200, { ok: true, log: `${log1}\n${log2}`.trim() })
      } catch (e) {
        return sendJson(res, 500, { ok: false, error: String(e.stderr || e.message || e) })
      }
    })
    return
  }

  // ── 静态文件（站点根 = ios/，这样 ../Yimengqian/... 的相对路径能直接用）──
  let rel = url === '/' ? '/preview/index.html' : url
  const file = normalize(join(ROOT, rel))
  if (!file.startsWith(ROOT.endsWith(sep) ? ROOT : ROOT + sep)) {
    res.writeHead(403); return res.end('forbidden')
  }
  if (!existsSync(file) || !statSync(file).isFile()) {
    res.writeHead(404); return res.end('not found: ' + rel)
  }
  res.writeHead(200, {
    'Content-Type': MIME[extname(file).toLowerCase()] || 'application/octet-stream',
    'Cache-Control': 'no-store'
  })
  res.end(readFileSync(file))
})

server.listen(PORT, '127.0.0.1', () => {
  const url = `http://127.0.0.1:${PORT}/preview/index.html?edit=1`
  console.log(`\n热区编辑器已启动：${url}`)
  console.log('  拖动热区移动 · 拖右下角改大小 · 选中后方向键微调（Shift 加速）')
  console.log('  点「保存到仓库」写回 tools/hotspot-overrides.ios.json 并重新生成 Swift')
  console.log('  按 Ctrl+C 结束\n')
  if (!process.argv.includes('--no-open')) {
    try { execFileSync('cmd', ['/c', 'start', '', url], { stdio: 'ignore' }) } catch {}
  }
})

server.on('error', (e) => {
  if (e.code === 'EADDRINUSE') console.error(`端口 ${PORT} 已被占用，换一个：$env:PORT=7799; node tools/hotspot-server.mjs`)
  else console.error(e)
  process.exit(1)
})
