// 扫屏回归：每张截图与对应设计稿做粗网格比对（缩到 24×52 采样点，算平均色差）。
// 用途：证明 25 屏都真的渲染了**对应的**设计稿（取错图 / 白屏 / 只有叠层没有底图都会露出来）。
import { readFileSync, readdirSync } from 'node:fs'
import { inflateSync } from 'node:zlib'
import { join } from 'node:path'

function decode(file) {
  const b = readFileSync(file)
  let o = 8, w = 0, h = 0, ct = 0
  const id = []
  while (o < b.length) {
    const l = b.readUInt32BE(o), t = b.toString('ascii', o + 4, o + 8), d = b.subarray(o + 8, o + 8 + l)
    if (t === 'IHDR') { w = d.readUInt32BE(0); h = d.readUInt32BE(4); ct = d[9] }
    else if (t === 'IDAT') id.push(d)
    else if (t === 'IEND') break
    o += 12 + l
  }
  const ch = { 0: 1, 2: 3, 4: 2, 6: 4 }[ct]
  const raw = inflateSync(Buffer.concat(id))
  const st = w * ch
  const px = Buffer.alloc(st * h)
  const pa = (a, b2, c) => { const p = a + b2 - c, x = Math.abs(p - a), y = Math.abs(p - b2), z = Math.abs(p - c); return x <= y && x <= z ? a : y <= z ? b2 : c }
  let prev = Buffer.alloc(st)
  for (let y = 0; y < h; y++) {
    const f = raw[y * (st + 1)]
    const src = raw.subarray(y * (st + 1) + 1, y * (st + 1) + 1 + st)
    const row = px.subarray(y * st, y * st + st)
    for (let x = 0; x < st; x++) {
      const a = x >= ch ? row[x - ch] : 0, bb = prev[x], c = x >= ch ? prev[x - ch] : 0
      let v = src[x]
      if (f === 1) v += a; else if (f === 2) v += bb; else if (f === 3) v += (a + bb) >> 1; else if (f === 4) v += pa(a, bb, c)
      row[x] = v & 255
    }
    prev = row
  }
  return { w, h, ch, px }
}

function grid(img, cols = 24, rowsN = 52) {
  const out = []
  for (let ry = 0; ry < rowsN; ry++) {
    for (let rx = 0; rx < cols; rx++) {
      const x = Math.floor(((rx + 0.5) / cols) * img.w)
      const y = Math.floor(((ry + 0.5) / rowsN) * img.h)
      const i = (y * img.w + x) * img.ch
      out.push([img.px[i], img.px[i + 1], img.px[i + 2]])
    }
  }
  return out
}

const sweepDir = process.argv[2]
const designDir = process.argv[3]
const shots = readdirSync(sweepDir).filter((f) => f.endsWith('.png')).sort()
const results = []
for (const f of shots) {
  const id = f.replace('.png', '')
  let design
  try { design = decode(join(designDir, id + '.png')) } catch { results.push({ id, diff: NaN, note: '无设计稿' }); continue }
  const shot = decode(join(sweepDir, f))
  const a = grid(design), b = grid(shot)
  let sum = 0
  for (let i = 0; i < a.length; i++) {
    sum += (Math.abs(a[i][0] - b[i][0]) + Math.abs(a[i][1] - b[i][1]) + Math.abs(a[i][2] - b[i][2])) / 3
  }
  results.push({ id, diff: sum / a.length })
}
results.sort((x, y) => y.diff - x.diff)
console.log('屏'.padEnd(22), '与设计稿平均色差')
for (const r of results) console.log(r.id.padEnd(22), Number.isNaN(r.diff) ? r.note : r.diff.toFixed(1))
const bad = results.filter((r) => !Number.isNaN(r.diff) && r.diff > 45)
const good = results.filter((r) => !Number.isNaN(r.diff) && r.diff <= 45)
console.log(`\n通过 ${good.length} / ${results.length}（阈值 45）`)
console.log('可疑：', bad.length ? bad.map((d) => `${d.id}(${d.diff.toFixed(1)})`).join(', ') : '无')
