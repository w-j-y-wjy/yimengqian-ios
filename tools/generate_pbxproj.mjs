// 一梦千年 iOS —— Xcode 工程文件生成器
// 扫描 Yimengqian/Yimengqian 下的 .swift 文件与固定资源，生成 project.pbxproj（objectVersion 56，Xcode 14+ 兼容）
// 用法：node tools/generate_pbxproj.mjs
import { readdirSync, readFileSync, statSync, writeFileSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('..', import.meta.url)); // ios/
const PROJ_DIR = path.join(ROOT, 'Yimengqian');
const APP_DIR = path.join(PROJ_DIR, 'Yimengqian');
const OUT = path.join(PROJ_DIR, 'Yimengqian.xcodeproj', 'project.pbxproj');

const id = (seed) => createHash('md5').update(seed).digest('hex').substring(0, 24).toUpperCase();

// —— 收集 Swift 文件（按目录分组，保持稳定排序）——
function collectSwiftFiles(dir) {
  const out = [];
  for (const name of readdirSync(dir).sort()) {
    const full = path.join(dir, name);
    if (statSync(full).isDirectory()) {
      out.push(...collectSwiftFiles(full));
    } else if (name.endsWith('.swift')) {
      out.push(full);
    }
  }
  return out;
}
const swiftFiles = collectSwiftFiles(APP_DIR);
if (!swiftFiles.length) throw new Error('未找到任何 Swift 文件');

// —— 固定文件引用 ——
const hasAssets = existsSync(path.join(APP_DIR, 'Assets.xcassets'));
const hasInfoPlist = existsSync(path.join(APP_DIR, 'Info.plist'));
const hasPrivacy = existsSync(path.join(APP_DIR, 'PrivacyInfo.xcprivacy'));

// 资源目录探测（2026-10-19 修正）
// 历史：目录曾叫 Resources，后来改名 Content；真正要打包进 App 的只有 Content/Screens 下的 25 张设计稿。
// 旧脚本只认 Resources，于是重跑会生成一个「不含任何资源目录」的工程 → 25 屏全部缺图。
// 另外 Content/Reference 是死资源（无视图渲染、且文件名与内容错配），不参与打包。
const SCREENS_REL = 'Content/Screens';
const screensRel = existsSync(path.join(APP_DIR, SCREENS_REL))
  ? SCREENS_REL
  : (existsSync(path.join(APP_DIR, 'Resources')) ? 'Resources' : null);
if (!screensRel) {
  throw new Error('未找到资源目录（Content/Screens 与 Resources 都不存在）。拒绝生成不含资源的工程——请先确认设计稿在磁盘上。');
}

// 内容配图目录（目前是 Content/ArtApp）：从 ContentData.swift 的 image 引用推导。
// 为什么必须推导而不是写死：2026-10-20 重跑本脚本时，手工加进 pbxproj 的 ArtApp 引用被
// 静默丢掉，26 张内容配图全都不进包（App 里全是白图），而磁盘与 ContentData 看着都正常。
// static-check 的 content.bundle 会拦这一条，但拦不住"已经推上去才发现"，所以源头要自洽。
const CONTENT_ROOT = path.join(APP_DIR, 'Content');
const contentDirs = (() => {
  const cdPath = path.join(APP_DIR, 'Models', 'ContentData.swift');
  const out = new Set();
  if (existsSync(cdPath)) {
    const src = readFileSync(cdPath, 'utf8').replace(/\/\/[^\n]*/g, '');
    for (const m of src.matchAll(/image:\s*"([^"]+)"/g)) {
      const top = m[1].split('/')[0];
      // Reference/ 是死资源（无视图渲染、文件名与内容错配），明确排除
      if (top && top !== 'Reference' && top !== 'Screens') out.add(top);
    }
  }
  return [...out]
    .filter((d) => {
      const p = path.join(CONTENT_ROOT, d);
      return existsSync(p) && statSync(p).isDirectory();
    })
    .sort();
})();
if (contentDirs.length) console.log(`[pbxproj] 内容配图目录：${contentDirs.join(', ')}`);

/// 需要以「文件夹引用」方式整目录进包的资源：设计稿 + 各内容配图目录
const resourceFolders = [
  { name: 'Screens', rel: screensRel },
  ...contentDirs.map((d) => ({ name: d, rel: `Content/${d}` })),
];

const FR = (p) => `FR-${p}`;
const BF = (p) => `BF-${p}`;
const fileRefId = (p) => id(FR(p));
const buildFileId = (p) => id(BF(p));

// 目录分组：相对 APP_DIR 的一级目录名 → 组名；其余文件放根组
const dirs = [...new Set(swiftFiles.map((f) => path.relative(APP_DIR, path.dirname(f))))];
const groupOf = {};
for (const d of dirs) {
  groupOf[d] = id(`G-${d}`);
}
const rootGroupId = id('G-ROOT');
const productsGroupId = id('G-PRODUCTS');
const targetId = id('T-Yimengqian');
const projectId = id('P-Yimengqian');
const sourcesPhaseId = id('PH-SOURCES');
const frameworksPhaseId = id('PH-FRAMEWORKS');
const resourcesPhaseId = id('PH-RESOURCES');
const projectConfigListId = id('CL-PROJECT');
const targetConfigListId = id('CL-TARGET');
const projDebugId = id('BC-PROJ-DEBUG');
const projReleaseId = id('BC-PROJ-RELEASE');
const tgtDebugId = id('BC-TGT-DEBUG');
const tgtReleaseId = id('BC-TGT-RELEASE');
const appProductRefId = id('PRD-Yimengqian.app');

// —— 组 ——
const groupSections = [];
const rootChildren = [];
const rootChildIds = [];
for (const d of dirs) {
  const files = swiftFiles.filter((f) => path.relative(APP_DIR, path.dirname(f)) === d).sort();
  const childIds = files.map((f) => fileRefId(path.relative(APP_DIR, f)));
  const gid = groupOf[d];
  groupSections.push(`\t\t${gid} /* ${d} */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n${childIds.map((c) => `\t\t\t\t${c} /* ${path.basename(files[childIds.indexOf(c)])} */,`).join('\n')}\n\t\t\t);\n\t\t\tpath = ${d};\n\t\t\tsourceTree = "<group>";\n\t\t};`);
  rootChildren.push(...files.map((f) => ({ id: fileRefId(path.relative(APP_DIR, f)), name: path.basename(f), gid })));
  rootChildIds.push(gid);
}
// 固定项
const fixedRefs = [];
if (hasAssets) { fixedRefs.push({ id: fileRefId('Assets.xcassets'), name: 'Assets.xcassets', fileRef: `{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };` }); rootChildIds.push(fileRefId('Assets.xcassets')); }
if (hasInfoPlist) { fixedRefs.push({ id: fileRefId('Info.plist'), name: 'Info.plist', fileRef: `{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };` }); rootChildIds.push(fileRefId('Info.plist')); }
for (const folder of resourceFolders) {
  fixedRefs.push({ id: fileRefId(folder.name), name: folder.name, fileRef: `{isa = PBXFileReference; lastKnownFileType = folder; path = "${folder.rel}"; sourceTree = "<group>"; };` });
  rootChildIds.push(fileRefId(folder.name));
}
if (hasPrivacy) { fixedRefs.push({ id: fileRefId('PrivacyInfo.xcprivacy'), name: 'PrivacyInfo.xcprivacy', fileRef: `{isa = PBXFileReference; lastKnownFileType = text.xml; path = PrivacyInfo.xcprivacy; sourceTree = "<group>"; };` }); rootChildIds.push(fileRefId('PrivacyInfo.xcprivacy')); }

// —— 文件引用段 ——
const fileRefLines = [];
for (const f of swiftFiles) {
  const rel = path.relative(APP_DIR, f);
  fileRefLines.push(`\t\t${fileRefId(rel)} /* ${path.basename(f)} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ${path.basename(f)}; sourceTree = "<group>"; };`);
}
for (const fr of fixedRefs) fileRefLines.push(`\t\t${fr.id} /* ${fr.name} */ = ${fr.fileRef}`);
fileRefLines.push(`\t\t${appProductRefId} /* Yimengqian.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Yimengqian.app; sourceTree = BUILT_PRODUCTS_DIR; };`);

// —— 构建文件段（Sources 全部 swift；Resources = Assets + Resources 文件夹）——
const buildFileLines = [];
const sourceBuildIds = [];
for (const f of swiftFiles) {
  const rel = path.relative(APP_DIR, f);
  const bid = buildFileId(rel);
  buildFileLines.push(`\t\t${bid} /* ${path.basename(f)} in Sources */ = {isa = PBXBuildFile; fileRef = ${fileRefId(rel)} /* ${path.basename(f)} */; };`);
  sourceBuildIds.push(bid);
}
const resourceBuildIds = [];
if (hasAssets) {
  const bid = buildFileId('Assets.xcassets');
  buildFileLines.push(`\t\t${bid} /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = ${fileRefId('Assets.xcassets')} /* Assets.xcassets */; };`);
  resourceBuildIds.push(bid);
}
for (const folder of resourceFolders) {
  const bid = buildFileId(folder.name);
  buildFileLines.push(`\t\t${bid} /* ${folder.name} in Resources */ = {isa = PBXBuildFile; fileRef = ${fileRefId(folder.name)} /* ${folder.name} */; };`);
  resourceBuildIds.push(bid);
}
if (hasPrivacy) {
  const bid = buildFileId('PrivacyInfo.xcprivacy');
  buildFileLines.push(`\t\t${bid} /* PrivacyInfo.xcprivacy in Resources */ = {isa = PBXBuildFile; fileRef = ${fileRefId('PrivacyInfo.xcprivacy')} /* PrivacyInfo.xcprivacy */; };`);
  resourceBuildIds.push(bid);
}

// —— 组装 ——
const pbx = `// !$*UTF8*$!
{
\tarchiveVersion = 1;
\tclasses = {
\t};
\tobjectVersion = 56;
\tobjects = {

/* Begin PBXBuildFile section */
${buildFileLines.join('\n')}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
${fileRefLines.join('\n')}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t${frameworksPhaseId} /* Frameworks */ = {
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t${rootGroupId} = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
${rootChildIds.map((c) => `\t\t\t\t${c},`).join('\n')}
\t\t\t);
\t\t\tpath = Yimengqian;
\t\t\tsourceTree = "<group>";
\t\t};
${groupSections.join('\n')}
\t\t${productsGroupId} /* Products */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t${appProductRefId} /* Yimengqian.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t${targetId} /* Yimengqian */ = {
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = ${targetConfigListId} /* Build configuration list for PBXNativeTarget "Yimengqian" */;
\t\t\tbuildPhases = (
\t\t\t\t${sourcesPhaseId} /* Sources */,
\t\t\t\t${frameworksPhaseId} /* Frameworks */,
\t\t\t\t${resourcesPhaseId} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = Yimengqian;
\t\t\tproductName = Yimengqian;
\t\t\tproductReference = ${appProductRefId} /* Yimengqian.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t${projectId} /* Project object */ = {
\t\t\tisa = PBXProject;
\t\t\tattributes = {
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1500;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {
\t\t\t\t\t${targetId} = {
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t};
\t\t\t\t};
\t\t\t};
\t\t\tbuildConfigurationList = ${projectConfigListId} /* Build configuration list for PBXProject "Yimengqian" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = "zh-Hans";
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t\t"zh-Hans",
\t\t\t);
\t\t\tmainGroup = ${rootGroupId};
\t\t\tproductRefGroup = ${productsGroupId} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t${targetId} /* Yimengqian */,
\t\t\t);
\t\t};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t${resourcesPhaseId} /* Resources */ = {
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
${resourceBuildIds.map((b) => `\t\t\t\t${b},`).join('\n')}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t${sourcesPhaseId} /* Sources */ = {
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
${sourceBuildIds.map((b) => `\t\t\t\t${b} /* in Sources */,`).join('\n')}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t${projDebugId} /* Debug */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu11;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t};
\t\t\tname = Debug;
\t\t};
\t\t${projReleaseId} /* Release */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu11;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t};
\t\t\tname = Release;
\t\t};
\t\t${tgtDebugId} /* Debug */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = Yimengqian/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.yimeng.qiannian;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t};
\t\t\tname = Debug;
\t\t};
\t\t${tgtReleaseId} /* Release */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = Yimengqian/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.yimeng.qiannian;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t};
\t\t\tname = Release;
\t\t};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t${projectConfigListId} /* Build configuration list for PBXProject "Yimengqian" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t${projDebugId} /* Debug */,
\t\t\t\t${projReleaseId} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};
\t\t${targetConfigListId} /* Build configuration list for PBXNativeTarget "Yimengqian" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t${tgtDebugId} /* Debug */,
\t\t\t\t${tgtReleaseId} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};
/* End XCConfigurationList section */
\t};
\trootObject = ${projectId} /* Project object */;
}
`;

writeFileSync(OUT, pbx, 'utf8');
console.log(`[pbxproj] 已生成 ${OUT}`);
console.log(`[pbxproj] Swift 文件 ${swiftFiles.length} 个；资源：Assets=${hasAssets} Info.plist=${hasInfoPlist} 设计稿目录=${screensRel} PrivacyInfo=${hasPrivacy}`);
