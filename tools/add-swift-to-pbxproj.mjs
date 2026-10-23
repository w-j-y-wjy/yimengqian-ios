// add-swift-to-pbxproj.mjs
//
// 把新增的 .swift 文件登记进 Xcode 工程的四种位置：
//   PBXBuildFile / PBXFileReference / 所属 group 的 children / Sources build phase
//
// 为什么需要它：本机是 Windows、没有 Xcode，只能手写 pbxproj。
// 少登记任何一处，CI 上都会报 "cannot find X in scope"（文件没进编译）——
// 而且报错位置往往指向调用方，很容易误判成语法错误。
//
// 用法：node tools/add-swift-to-pbxproj.mjs <相对 Yimengqian/ 目录的路径> [...]
//   例：node tools/add-swift-to-pbxproj.mjs Engine/TorchCenter.swift
// 幂等：已经登记过的文件会跳过。

import { readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const PBX = join(ROOT, 'Yimengqian', 'Yimengqian.xcodeproj', 'project.pbxproj');
const BASE = 'Yimengqian'; // 工程内源根的相对基准（group path 相对这个目录）

const groupFor = (relPath) => {
  const dir = dirname(relPath);
  if (dir === '.') return null;
  return dir; // 例：Engine / Views/Native / Utilities
};

const idFor = (seed) => createHash('md5').update(seed).digest('hex').slice(0, 24).toUpperCase();

let text = readFileSync(PBX, 'utf8');
const targets = process.argv.slice(2);
if (!targets.length) {
  console.error('用法：node tools/add-swift-to-pbxproj.mjs <相对路径> [...]');
  process.exit(1);
}

let added = 0;
let skipped = 0;

for (const rel of targets) {
  const name = rel.split('/').pop();
  if (text.includes(`/* ${name} */ = {isa = PBXFileReference`)) {
    console.log(`[skip] ${rel} 已登记`);
    skipped += 1;
    continue;
  }

  const fileRef = idFor(`fileref:${rel}`);
  const buildFile = idFor(`buildfile:${rel}`);

  // 1) PBXBuildFile —— 紧跟在任意一条 "in Sources" 记录之后（同段即可）
  const bfAnchor = text.match(/^(\t\t)([0-9A-F]{24}) \/\* [^*]+ in Sources \*\/ = \{isa = PBXBuildFile;.*$/m);
  if (!bfAnchor) throw new Error('找不到 PBXBuildFile 段落锚点');
  const bfLine = `${bfAnchor[1]}${buildFile} /* ${name} in Sources */ = {isa = PBXBuildFile; fileRef = ${fileRef} /* ${name} */; };`;
  text = text.slice(0, bfAnchor.index + bfAnchor[0].length) + '\n' + bfLine + text.slice(bfAnchor.index + bfAnchor[0].length);

  // 2) PBXFileReference —— 紧跟任意一条 PBXFileReference 记录之后
  const frAnchor = text.match(/^(\t\t)([0-9A-F]{24}) \/\* [^*]+ \*\/ = \{isa = PBXFileReference;.*$/m);
  if (!frAnchor) throw new Error('找不到 PBXFileReference 段落锚点');
  const frLine = `${frAnchor[1]}${fileRef} /* ${name} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ${name}; sourceTree = "<group>"; };`;
  text = text.slice(0, frAnchor.index + frAnchor[0].length) + '\n' + frLine + text.slice(frAnchor.index + frAnchor[0].length);

  // 3) group children —— 找 path = <dir>; 的那个 group，把文件插进它的 children
  //
  // 陷阱（实测踩过）：不能用一个跨 group 的贪婪正则去配 `children = ( ... ); path = X`，
  // 那样会从**第一个** group 的 children 一路吃到目标 group，文件被塞进根 group。
  // 正确做法：从 `path = "X";` 反查最近的 `children = (`，再找它对应的 `);`。
  const groupDir = groupFor(rel);
  if (groupDir) {
    // pbxproj 两种写法都存在：单段 path = Engine;  带斜杠的也可能不带引号 path = Views/Native;
    // 所以两种都试，命中哪个用哪个（不要按"带斜杠一定加引号"去猜）。
    const candidates = [`path = "${groupDir}";`, `path = ${groupDir};`];
    let pathIdx = -1;
    for (const marker of candidates) {
      const idx = text.indexOf(marker);
      if (idx >= 0) { pathIdx = idx; break; }
    }
    if (pathIdx < 0) {
      throw new Error(`找不到 group：${groupDir}（新目录要先在工程里建 group，本脚本不代建）`);
    }
    // 从 path 往前找最近的 children = (
    const childrenIdx = text.lastIndexOf('children = (', pathIdx);
    if (childrenIdx < 0) throw new Error(`${groupDir} 的 group 没有 children`);
    // 从 children 往后找它的收尾 );（group children 里不会有嵌套，取最近的即可）
    const closeIdx = text.indexOf(');', childrenIdx);
    if (closeIdx < 0 || closeIdx > pathIdx) throw new Error(`${groupDir} 的 children 结构异常`);
    // 插在收尾之前，保持列表末尾
    text = text.slice(0, closeIdx) + `\t\t\t\t${fileRef} /* ${name} */,\n` + text.slice(closeIdx);
  } else {
    // 顶层文件（如 App 目录下的）挂到第一个 children 里即可
    const gm = text.match(/children = \(/);
    if (!gm) throw new Error('找不到任何 group children');
    const insertAt = gm.index + gm[0].length;
    text = text.slice(0, insertAt) + `\n\t\t\t\t${fileRef} /* ${name} */,` + text.slice(insertAt);
  }

  // 4) Sources build phase —— 在 files = ( 之后插入
  const spRe = /isa = PBXSourcesBuildPhase;[\s\S]*?files = \(/;
  const sp = text.match(spRe);
  if (!sp) throw new Error('找不到 PBXSourcesBuildPhase');
  const spAt = sp.index + sp[0].length;
  text = text.slice(0, spAt) + `\n\t\t\t\t${buildFile} /* ${name} in Sources */,` + text.slice(spAt);

  console.log(`[add ] ${rel}  fileRef=${fileRef} buildFile=${buildFile}`);
  added += 1;
}

writeFileSync(PBX, text, 'utf8');
console.log(`[done] 新增 ${added} 个，跳过 ${skipped} 个`);
