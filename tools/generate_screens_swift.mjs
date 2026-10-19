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

// —— 2. 读取覆盖并合并 ——
const readJson = (p, fallback) => (existsSync(p) ? JSON.parse(readFileSync(p, 'utf8')) : fallback);
const overrides = JSON.parse(readFileSync(OVERRIDES_JSON, 'utf8'));
const iosOverrides = readJson(IOS_OVERRIDES, {});
const deletions = readJson(IOS_DELETIONS, {});

let deletedCount = 0;
let iosOverrideCount = 0;
const merged = screens.map((s) => {
  const ovA = overrides[s.id] || {};
  const ovI = iosOverrides[s.id] || {};
  const del = new Set(deletions[s.id] || []);
  if (del.size) deletedCount += s.hotspots.filter((h) => del.has(h.id)).length;
  if (Object.keys(ovI).length) iosOverrideCount += Object.keys(ovI).length;
  return {
    ...s,
    hotspots: s.hotspots
      .filter((h) => !del.has(h.id))
      .map((h) => {
        const o = ovI[h.id] || ovA[h.id];   // iOS 侧优先
        if (!o) return h;
        return { ...h, x: o.x, y: o.y, width: o.width, height: o.height };
      }),
  };
});
const overriddenCount = Object.keys(overrides).length;
console.log(`[cfg] 合并 ${overriddenCount} 个屏幕的安卓坐标覆盖`);
if (iosOverrideCount) console.log(`[cfg] 叠加 ${iosOverrideCount} 条 iOS 侧坐标修正`);
if (deletedCount) console.log(`[cfg] 按删除清单剔除 ${deletedCount} 个热区`);

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

const actionCases = [
  'navigate', 'back', 'toast', 'storage', 'storageAndToast', 'conditionalNavigate',
  'setStorageAndToast', 'toggleStorage', 'storageAndNavigate', 'conditionalStorageNavigate',
  'incrementOnce', 'delayedNavigate', 'conditionalJump', 'setDefaultsAndNavigate', 'checkAnswer',
];
const isCase = (t) => actionCases.includes(t);

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
