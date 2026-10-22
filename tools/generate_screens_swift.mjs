// 一梦千年 iOS —— 热区配置生成器
// 输入：安卓工程 screens.ts + hotspot-overrides.json
// 输出：Yimengqian/Yimengqian/Config/ScreensConfig.swift
// 用法：node tools/generate_screens_swift.mjs
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const ROOT = fileURLToPath(new URL('..', import.meta.url)); // ios/
// 安卓工程位置：默认取与本仓库同级的 ../安卓/一梦千年-App；
// 可用环境变量 YIMENG_ANDROID 覆盖。
// 原实现硬编码 'D:/wij/桌面/...'，在 macOS 上必然找不到 → 脚本不可移植。
const ANDROID = process.env.YIMENG_ANDROID
  ? path.resolve(process.env.YIMENG_ANDROID)
  : path.resolve(ROOT, '..', '安卓', '一梦千年-App');
const SCREENS_TS = path.join(ANDROID, 'app-project', 'src', 'config', 'screens.ts');
const OVERRIDES_JSON = path.join(ANDROID, 'app-project', 'src', 'config', 'hotspot-overrides.json');
// iOS 侧修正（本仓库内，随 iOS 工程一起版本化）：
//   坐标覆盖优先级 安卓 hotspot-overrides.json < tools/hotspot-overrides.ios.json
//   删除清单只在本仓库内生效，不改动安卓源工程。
// 为什么要有它们：Phase 1 修的热区如果只落在生成物 ScreensConfig.swift 里，
// 一旦重跑生成器就会静默回退。把修正回写到源头，重跑才是幂等的。
const IOS_OVERRIDES = path.join(ROOT, 'tools', 'hotspot-overrides.ios.json');
const IOS_DELETIONS = path.join(ROOT, 'tools', 'hotspot-deletions.json');
const OUT_DEFAULT = path.join(ROOT, 'Yimengqian', 'Yimengqian', 'Config', 'ScreensConfig.swift');
const outArg = process.argv.slice(2).find((a) => a.startsWith('--out='));
const OUT = outArg ? path.resolve(ROOT, outArg.slice('--out='.length)) : OUT_DEFAULT;

if (!existsSync(SCREENS_TS)) {
  throw new Error(
    `找不到安卓源配置：${SCREENS_TS}\n` +
    `这个脚本只在「改了安卓 screens.ts、需要重新生成 ScreensConfig.swift」时才要跑。\n` +
    `请把安卓工程放到 ../安卓/一梦千年-App，或设置环境变量 YIMENG_ANDROID 指向它。`
  );
}

// —— 1. 通过 Node 23 type-stripping 直接导入 TS 源文件 ——
const tsUrl = new URL(`file:///${SCREENS_TS.replace(/\\/g, '/')}`);
const { screens } = await import(tsUrl.href);
console.log(`[cfg] 从 screens.ts 读取 ${screens.length} 个屏幕`);

// 15 种动作类型白名单。定义在合并之前：合并阶段要用它校验 iOS 侧的动作覆盖，
// 若留到后面会触发 TDZ（Cannot access 'isCase' before initialization）。
const actionCases = [
  'navigate', 'back', 'toast', 'storage', 'storageAndToast', 'conditionalNavigate',
  'setStorageAndToast', 'toggleStorage', 'storageAndNavigate', 'conditionalStorageNavigate',
  'incrementOnce', 'delayedNavigate', 'conditionalJump', 'setDefaultsAndNavigate', 'checkAnswer',
  // 朗读：用系统 AVSpeechSynthesizer 念出指定文本（不需要音频素材）
  'speakText',
];
const isCase = (t) => actionCases.includes(t);

// —— 2. 读取覆盖并合并 ——
const readJson = (p, fallback) => (existsSync(p) ? JSON.parse(readFileSync(p, 'utf8')) : fallback);
const overrides = JSON.parse(readFileSync(OVERRIDES_JSON, 'utf8'));
const iosOverrides = readJson(IOS_OVERRIDES, {});
const deletions = readJson(IOS_DELETIONS, {});
// 新增热区清单（本仓库维护）：设计稿上画了可点元素、但安卓源里没有热区的情况。
// 表结构：{ "<屏 id>": [ { id, label, x, y, width, height, action: {…} }, … ] }
// 为什么放在生成器而不是手改 ScreensConfig：手改会被下一次生成静默回退（本文件是生成物）。
const IOS_ADDITIONS = path.join(ROOT, 'tools', 'hotspot-additions.ios.json');
const additions = readJson(IOS_ADDITIONS, {});

let deletedCount = 0;
let iosOverrideCount = 0;
let actionOverrideCount = 0;
let additionCount = 0;
const merged = screens.map((s) => {
  const ovA = overrides[s.id] || {};
  const ovI = iosOverrides[s.id] || {};
  const del = new Set(deletions[s.id] || []);
  const add = Array.isArray(additions[s.id]) ? additions[s.id] : [];
  if (del.size) deletedCount += s.hotspots.filter((h) => del.has(h.id)).length;
  if (Object.keys(ovI).length) iosOverrideCount += Object.keys(ovI).length;

  // 新增热区：先校验，再追加到尾部（ZStack 里后绘制者在上层，新增的贴合元素的一小块
  // 不容易被已有大热区抢走，但仍要求不与已有 id 冲突、矩形在画面内）
  const added = add.map((h, i) => {
    const where = `${s.id}/${h.id || `#${i}`}`;
    if (!h.id || typeof h.id !== 'string') throw new Error(`hotspot-additions.ios.json: ${where} 缺 id`);
    if (s.hotspots.some((x) => x.id === h.id)) throw new Error(`hotspot-additions.ios.json: ${where} 与已有热区 id 重复`);
    for (const k of ['x', 'y', 'width', 'height']) {
      if (typeof h[k] !== 'number') throw new Error(`hotspot-additions.ios.json: ${where} 的 ${k} 必须是数字`);
    }
    if (h.width <= 0 || h.height <= 0) throw new Error(`hotspot-additions.ios.json: ${where} 尺寸必须为正`);
    if (h.x < 0 || h.y < 0 || h.x + h.width > 100.5 || h.y + h.height > 100.5) {
      throw new Error(`hotspot-additions.ios.json: ${where} 超出画面（x+w=${h.x + h.width} y+h=${h.y + h.height}）`);
    }
    if (!h.action || !isCase(h.action.type)) {
      throw new Error(`hotspot-additions.ios.json: ${where} 的 action.type 非法`);
    }
    additionCount += 1;
    return { id: h.id, label: h.label || h.id, x: h.x, y: h.y, width: h.width, height: h.height, action: h.action };
  });

  return {
    ...s,
    hotspots: s.hotspots
      .filter((h) => !del.has(h.id))
      .map((h) => {
        const oA = ovA[h.id];
        const oI = ovI[h.id];
        if (!oA && !oI) return h;

        // 坐标：iOS 侧优先。**只有给了数值才覆盖** —— 允许一条覆盖只写 action
        // （旧写法 `x: o.x` 在字段缺失时会变成 undefined，最后被 swNum 序列化成 0，
        //  热区会静默塌缩到左上角，这类"改动作顺手把坐标清零"的坑必须提前堵住。
        const rect = {};
        for (const src of [oA, oI]) {
          if (!src) continue;
          for (const k of ['x', 'y', 'width', 'height']) {
            if (typeof src[k] === 'number') rect[k] = src[k];
          }
        }

        // 动作：只认 iOS 侧，且**整条替换**（不做字段级合并 —— 否则从
        // setStorageAndToast 改成 navigate 时，旧的 storageKey/message 会残留在配置里）。
        // 为什么不在安卓 hotspot-overrides.json 里改动作：那是安卓源工程的修正层，
        // iOS 这边发现的动作错误不应反向污染另一个仓库。
        let action = h.action;
        if (oI && oI.action) {
          if (!isCase(oI.action.type)) {
            throw new Error(
              `tools/hotspot-overrides.ios.json 里 ${s.id}/${h.id} 的 action.type 非法：${JSON.stringify(oI.action.type)}`
            );
          }
          action = oI.action;
          actionOverrideCount += 1;
        }

        return { ...h, ...rect, action };
      })
      .concat(added),
  };
});
const overriddenCount = Object.keys(overrides).length;
console.log(`[cfg] 合并 ${overriddenCount} 个屏幕的安卓坐标覆盖`);
if (iosOverrideCount) console.log(`[cfg] 叠加 ${iosOverrideCount} 条 iOS 侧修正（坐标 / 动作）`);
if (actionOverrideCount) console.log(`[cfg] 按 iOS 侧修正替换 ${actionOverrideCount} 条动作`);
if (deletedCount) console.log(`[cfg] 按删除清单剔除 ${deletedCount} 个热区`);
if (additionCount) console.log(`[cfg] 按新增清单补 ${additionCount} 个热区（设计稿上有可点元素、源配置里缺）`);

// —— 3. 工具函数 ——
const swStr = (s) => JSON.stringify(String(s)); // JSON 转义 ≈ Swift 字符串转义
const swNum = (n) => {
  if (typeof n !== 'number') return '0';
  return Number(n).toLocaleString('en-US', { useGrouping: false, maximumFractionDigits: 10 });
};

// 图片路径映射：/screens/x.png -> Screens/x.png ; /assets/reference/x.png -> Reference/x.png
const mapImage = (p) => {
  if (p.startsWith('/screens/')) return `Screens/${p.slice('/screens/'.length)}`;
  if (p.startsWith('/assets/reference/')) return `Reference/${p.slice('/assets/reference/'.length)}`;
  return p.replace(/^\//, '');
};

// iOS 侧的设计稿是按「屏 id」命名的（Content/Screens/<id>.png），
// 而安卓源里用的是中文文件名（如 一梦千年首页.png）。两边对不上时以 iOS 资源为准，
// 否则重新生成会把 25 条 image 全部改错 → App 整屏白屏。存在性判断即映射规则。
const IOS_SHOTS = path.join(ROOT, 'Yimengqian', 'Yimengqian', 'Content', 'Screens');
const mapImageForIos = (s) => {
  const guess = `${s.id}.png`;
  if (existsSync(path.join(IOS_SHOTS, guess))) return `Screens/${guess}`;
  return mapImage(s.image);
};

function emitAction(a) {
  if (!a || typeof a !== 'object') return 'HotspotAction(type: .toast)';
  const type = a.type;
  const parts = [];
  if (isCase(type)) parts.push(`type: .${type}`);
  else parts.push(`type: .toast`); // 防御：未知类型退化为 toast
  if (a.target != null) parts.push(`target: ${swStr(a.target)}`);
  if (a.message != null) parts.push(`message: ${swStr(a.message)}`);
  if (a.storageKey != null) parts.push(`storageKey: ${swStr(a.storageKey)}`);
  if (a.storageValue != null) parts.push(`storageValue: ${swStr(a.storageValue)}`);
  if (a.onMessage != null) parts.push(`onMessage: ${swStr(a.onMessage)}`);
  if (a.offMessage != null) parts.push(`offMessage: ${swStr(a.offMessage)}`);
  if (a.flagKey != null) parts.push(`flagKey: ${swStr(a.flagKey)}`);
  if (a.defaultValue != null) parts.push(`defaultValue: ${swStr(a.defaultValue)}`);
  if (a.delay != null) parts.push(`delay: ${swNum(a.delay)}`);
  if (a.correctAnswer != null) parts.push(`correctAnswer: ${swStr(a.correctAnswer)}`);
  // speakText 用 message 承载要朗读的文本（不再另造字段，保持 HotspotAction 结构不变）
  if (type === 'speakText' && a.text != null) parts.push(`message: ${swStr(a.text)}`);
  if (Array.isArray(a.storage) && a.storage.length) {
    parts.push(`storage: [${a.storage.map((kv) => `KV(key: ${swStr(kv.key)}, value: ${swStr(kv.value)})`).join(', ')}]`);
  }
  if (Array.isArray(a.defaults) && a.defaults.length) {
    parts.push(`defaults: [${a.defaults.map((kv) => `KV(key: ${swStr(kv.key)}, value: ${swStr(kv.value)})`).join(', ')}]`);
  }
  if (Array.isArray(a.storageFlags) && a.storageFlags.length) {
    parts.push(`storageFlags: [${a.storageFlags.map((kv) => `KV(key: ${swStr(kv.key)}, value: ${swStr(kv.value)})`).join(', ')}]`);
  }
  return `HotspotAction(${parts.join(', ')})`;
}

function emitScreen(s) {
  const hotspots = s.hotspots
    .map((h) => `Hotspot(id: ${swStr(h.id)}, label: ${swStr(h.label)}, x: ${swNum(h.x)}, y: ${swNum(h.y)}, width: ${swNum(h.width)}, height: ${swNum(h.height)}, action: ${emitAction(h.action)})`)
    .join(',\n                ');
  return `ScreenConfig(id: ${swStr(s.id)}, route: ${swStr(s.route)}, image: ${swStr(mapImageForIos(s))}, hotspots: [\n                ${hotspots}\n            ])`;
}

// —— 4. 组装 Swift 源码 ——
const header = `// 本文件由 tools/generate_screens_swift.mjs 自动生成 —— 请勿手动编辑。
// Generated from app-project/src/config/screens.ts + hotspot-overrides.json
//        + tools/hotspot-overrides.ios.json（iOS 侧坐标修正）+ tools/hotspot-deletions.json（删除清单）
// 共 ${merged.length} 个屏幕；合并了 ${overriddenCount} 个屏幕的坐标覆盖。
import Foundation

// MARK: - 键值对（storage / defaults / storageFlags 通用）
struct KV: Codable, Equatable {
    var key: String
    var value: String
}

// MARK: - 热区动作
struct HotspotAction: Codable, Equatable {
    enum Kind: String, Codable, Equatable, CaseIterable {
        case navigate
        case back
        case toast
        case storage
        case storageAndToast
        case conditionalNavigate
        case setStorageAndToast
        case toggleStorage
        case storageAndNavigate
        case conditionalStorageNavigate
        case incrementOnce
        case delayedNavigate
        case conditionalJump
        case setDefaultsAndNavigate
        case checkAnswer
        case speakText
    }
    var type: Kind
    var target: String?
    var message: String?
    var storage: [KV]?
    var storageKey: String?
    var storageValue: String?
    var onMessage: String?
    var offMessage: String?
    var flagKey: String?
    var defaultValue: String?
    var delay: Double?
    var defaults: [KV]?
    var correctAnswer: String?
    var storageFlags: [KV]?

    init(type: Kind, target: String? = nil, message: String? = nil, storage: [KV]? = nil,
         storageKey: String? = nil, storageValue: String? = nil, onMessage: String? = nil,
         offMessage: String? = nil, flagKey: String? = nil, defaultValue: String? = nil,
         delay: Double? = nil, defaults: [KV]? = nil, correctAnswer: String? = nil,
         storageFlags: [KV]? = nil) {
        self.type = type
        self.target = target
        self.message = message
        self.storage = storage
        self.storageKey = storageKey
        self.storageValue = storageValue
        self.onMessage = onMessage
        self.offMessage = offMessage
        self.flagKey = flagKey
        self.defaultValue = defaultValue
        self.delay = delay
        self.defaults = defaults
        self.correctAnswer = correctAnswer
        self.storageFlags = storageFlags
    }
}

// MARK: - 热区
struct Hotspot: Codable, Identifiable, Equatable {
    var id: String
    var label: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var action: HotspotAction
}

// MARK: - 屏幕配置
struct ScreenConfig: Codable, Identifiable, Equatable {
    var id: String
    var route: String
    var image: String
    var hotspots: [Hotspot]
}

// MARK: - 屏幕目录
enum ScreenCatalog {
    static let all: [ScreenConfig] = [
`;

const body = merged.map((s, i) => {
  const comma = i < merged.length - 1 ? ',' : '';
  return `        ${emitScreen(s)}${comma}`;
}).join('\n');

const footer = `
    ]

    static func screen(id: String) -> ScreenConfig? {
        all.first { $0.id == id }
    }

    static func screen(route: String) -> ScreenConfig? {
        all.first { $0.route == route }
    }
}
`;

writeFileSync(OUT, header + body + footer, 'utf8');
console.log(`[cfg] 已生成 ${OUT}`);
