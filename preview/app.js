/* 一梦千年 · 本地预览器
 *
 * 语义对齐 Engine/ActionExecutor.swift 的 15 种动作：
 * 这个文件做的事，就是把 Swift 里那 151 行动作分发，逐条翻成浏览器里能跑的行为。
 * 之所以要「逐条对齐」而不是「点了随便跳一下」，是因为预览器的价值就在于
 * 暴露真实跳转错误 —— 简化语义的预览器只会骗自己。
 *
 * 数据来自 index.html 内联的 ScreensConfig 快照（由 tools/preview.mjs 生成）。
 */
(function () {
  'use strict'

  // ── 载入配置 ────────────────────────────────────────────────────────────
  var data = JSON.parse(document.getElementById('screen-data').textContent)
  var screens = data.screens
  var byId = {}, byRoute = {}
  screens.forEach(function (s) { byId[s.id] = s; byRoute[s.route] = s })
  var TOTAL_HS = screens.reduce(function (n, s) { return n + s.hotspots.length }, 0)
  var TRACKED = new Set(data.trackedKeys)
  var DRAWN = new Set(data.visuallyRepresentedKeys)

  // ── 会话状态（存储模拟 + 覆盖统计，存 localStorage 便于刷新不丢）─────────
  var LS = 'yimeng-preview-v2'
  var state = { store: {}, clicked: [], visited: [], wrongOn: null }
  try {
    var raw = localStorage.getItem(LS)
    if (raw) Object.assign(state, JSON.parse(raw))
  } catch (e) { /* file:// 下某些浏览器禁写，忽略即可 */ }
  state.clicked = state.clicked || []
  state.visited = state.visited || []

  function persist () {
    try { localStorage.setItem(LS, JSON.stringify(state)) } catch (e) {}
  }

  // ── AppStore 的离散键语义 ───────────────────────────────────────────────
  var S = {
    get: function (k) { return Object.prototype.hasOwnProperty.call(state.store, k) ? state.store[k] : null },
    set: function (k, v) { state.store[k] = String(v); persist() },
    del: function (k) { delete state.store[k]; persist() },
    setIfAbsent: function (k, v) { if (S.get(k) === null) S.set(k, v) },
    toggle: function (k) {
      if (S.get(k) !== null) { S.del(k); return false }
      S.set(k, 'true'); return true
    },
    inc: function (k, by) {
      var n = (parseInt(S.get(k) || '0', 10) || 0) + (by || 1)
      S.set(k, n); return n
    },
    bool: function (k) { return S.get(k) === 'true' }
  }

  // ── 路由栈（对齐 Router.swift）───────────────────────────────────────────
  var stack = [byId[data.startScreen] || screens[0]]
  var problems = []
  var lastToast = null

  function navigate (route) {
    var s = byRoute[route]
    if (!s) { problems.push('目标屏不存在：' + route); addLog('×', '目标屏不存在：' + route); return false }
    stack.push(s)
    state.wrongOn = null
    return true
  }

  function back () {
    if (stack.length <= 1) return false
    stack.pop()
    state.wrongOn = null
    return true
  }

  function jump (screen) {
    stack = [screen]
    state.wrongOn = null
  }

  // ── 小工具 ──────────────────────────────────────────────────────────────
  function $(sel) { return document.querySelector(sel) }

  function el (tag, cls, text) {
    var n = document.createElement(tag)
    if (cls) n.className = cls
    if (text != null) n.textContent = text
    return n
  }

  function pct (v) { return v + '%' }

  var toastTimer = null
  function toast (msg) {
    var t = $('#toast')
    if (!msg) return
    lastToast = msg
    t.textContent = msg
    t.classList.remove('hidden')
    clearTimeout(toastTimer)
    toastTimer = setTimeout(function () { t.classList.add('hidden') }, 1800)
  }

  var logEntries = []
  function addLog (kind, text) {
    logEntries.unshift({ kind: kind, text: text, screen: stack[stack.length - 1].id })
    if (logEntries.length > 60) logEntries.length = 60
    renderLog()
  }

  // ── 诊断：越界 / 重复 / 目标悬空 / 重叠 ─────────────────────────────────
  function diagOf (s) {
    var out = []
    var ids = {}
    s.hotspots.forEach(function (h) {
      if (ids[h.id]) out.push('热区 id 重复：' + h.id)
      ids[h.id] = 1
      if (h.x + h.width > 100.01) out.push(h.id + ' 右越界 x+w=' + (h.x + h.width).toFixed(2))
      if (h.y + h.height > 100.01) out.push(h.id + ' 下越界 y+h=' + (h.y + h.height).toFixed(2))
      if (h.width <= 0 || h.height <= 0) out.push(h.id + ' 尺寸为零')
      if (h.action.target && !byRoute[h.action.target]) out.push(h.id + ' 目标不存在：' + h.action.target)
    })
    // 重叠：交叠面积超过较小热区的 35% → 可能互抢点击。
    // 外层卡片套内层按钮（如 daily-card 包 enter-poetry）行为一致，属正常嵌套，跳过。
    function sig (a) { return [a.type, a.target || '', a.storageKey || '', a.storageValue || ''].join('|') }
    for (var i = 0; i < s.hotspots.length; i++) {
      for (var j = i + 1; j < s.hotspots.length; j++) {
        var a = s.hotspots[i], b = s.hotspots[j]
        var ix = Math.max(0, Math.min(a.x + a.width, b.x + b.width) - Math.max(a.x, b.x))
        var iy = Math.max(0, Math.min(a.y + a.height, b.y + b.height) - Math.max(a.y, b.y))
        var inter = ix * iy
        if (inter <= 0) continue
        var minArea = Math.min(a.width * a.height, b.width * b.height)
        if (!(minArea > 0 && inter / minArea > 0.35)) continue
        if (sig(a.action) === sig(b.action)) continue
        out.push('热区重叠但行为不同：' + a.id + ' ↔ ' + b.id)
      }
    }
    return out
  }

  var diagCache = {}
  screens.forEach(function (s) { diagCache[s.id] = diagOf(s) })

  function oobSet (s) {
    var set = {}
    s.hotspots.forEach(function (h) {
      if (h.x + h.width > 100.01 || h.y + h.height > 100.01) set[h.id] = 1
    })
    return set
  }

  // ── 动作执行（逐条对齐 ActionExecutor.swift）────────────────────────────
  function execute (a, hs, sid) {
    switch (a.type) {
      case 'navigate':
        if (a.target) { navigate(a.target); addLog('→', hs.label + ' → ' + a.target) }
        break

      case 'back':
        addLog('←', hs.label + '（返回）')
        back()
        break

      case 'toast':
        toast(a.message || '')
        addLog('·', hs.label + '：' + (a.message || '（空提示）'))
        break

      case 'storage': {
        var list = a.storage || []
        list.forEach(function (kv) { S.set(kv.key, kv.value) })
        addLog('≡', hs.label + '：写入 ' + list.map(function (kv) { return kv.key }) .join(', '))
        break
      }

      case 'storageAndToast': {
        var l2 = a.storage || []
        l2.forEach(function (kv) { S.set(kv.key, kv.value); noteSelect(kv.key, kv.value, sid) })
        toast(a.message || '')
        addLog('≠', hs.label + '：写入并提示')
        break
      }

      case 'conditionalNavigate':
        if (S.get('dialogueTopic') === null) {
          toast(a.message || '请先选择一个话题')
          addLog('·', hs.label + '：未选话题，被拦下')
        } else {
          S.set('teaDialogueCompleted', 'true')
          if (a.target) { navigate(a.target); addLog('→', hs.label + ' → ' + a.target) }
        }
        break

      case 'setStorageAndToast': {
        var key = a.storageKey
        var val = a.storageValue == null ? 'true' : a.storageValue
        if (key) {
          S.set(key, val)
          noteSelect(key, val, sid)
          // 已经有叠层画出来的键 → 省掉 Toast（与 Swift 完全一致）
          if (!DRAWN.has(key)) toast(a.message || '')
          addLog('≠', hs.label + '：' + key + ' = ' + val)
        } else if (a.message) {
          toast(a.message)
        }
        break
      }

      case 'toggleStorage': {
        var k3 = a.storageKey
        if (!k3) break
        var on = S.toggle(k3)
        toast(on ? (a.onMessage || '已收藏') : (a.offMessage || '已取消'))
        addLog('⇄', hs.label + '：' + k3 + ' ' + (on ? '开' : '关'))
        break
      }

      case 'storageAndNavigate': {
        if (a.storageKey && a.target) {
          var v4 = a.storageValue == null ? a.target : a.storageValue
          S.set(a.storageKey, v4)
          noteSelect(a.storageKey, v4, sid)
          navigate(a.target)
          addLog('→', hs.label + '：' + a.storageKey + ' = ' + v4 + '，跳 ' + a.target)
        }
        break
      }

      case 'conditionalStorageNavigate': {
        if (a.storageKey && S.get(a.storageKey) === null) {
          var v5 = a.defaultValue == null ? 'true' : a.defaultValue
          S.set(a.storageKey, v5)
          noteSelect(a.storageKey, v5, sid)
        }
        if (a.target) { navigate(a.target); addLog('→', hs.label + ' → ' + a.target) }
        break
      }

      case 'incrementOnce': {
        var did = false
        if (a.flagKey && S.get(a.flagKey) === null) {
          S.set(a.flagKey, 'true')
          if (a.storageKey) S.inc(a.storageKey)
          did = true
        }
        toast(a.message || '')
        addLog('+1', hs.label + (did ? '：首次计数 +1' : '：已计过，不重复'))
        break
      }

      case 'delayedNavigate': {
        if (a.message) toast(a.message)
        if (a.target) {
          var d = a.delay == null ? 600 : a.delay
          addLog('⏱', hs.label + '：' + d + 'ms 后 → ' + a.target)
          setTimeout(function () { navigate(a.target); render() }, d)
        }
        break
      }

      case 'conditionalJump':
        if (S.bool('onboardingComplete')) {
          var home = byRoute['/home']
          if (home) { jump(home); addLog('⇥', hs.label + '：已完成引导，直达首页') }
        } else if (a.target) {
          navigate(a.target)
          addLog('→', hs.label + ' → ' + a.target)
        }
        break

      case 'setDefaultsAndNavigate': {
        (a.defaults || []).forEach(function (kv) {
          S.setIfAbsent(kv.key, kv.value)
          var actual = S.get(kv.key)
          if (actual !== null) noteSelect(kv.key, actual, sid)
        })
        if (a.target) { navigate(a.target); addLog('→', hs.label + ' → ' + a.target) }
        break
      }

      case 'checkAnswer': {
        var ans = a.storageKey ? S.get(a.storageKey) : null
        if (ans === null) {
          toast(a.message || '请先选择答案')
          addLog('?', hs.label + '：还没选答案')
        } else if (ans !== a.correctAnswer) {
          state.wrongOn = sid
          toast('回答错误，请重新选择')
          addLog('✗', hs.label + '：答案 ' + ans + ' 错（正确 ' + a.correctAnswer + '）')
        } else {
          state.wrongOn = null
          ;(a.storageFlags || []).forEach(function (kv) { S.set(kv.key, kv.value) })
          if (a.target) { navigate(a.target); addLog('✓', hs.label + '：答对，跳 ' + a.target) }
        }
        break
      }

      default:
        problems.push('未实现的动作类型：' + a.type + '（' + sid + '/' + hs.id + '）')
        addLog('?', hs.label + '：未实现的动作类型 ' + a.type)
    }
    if (!QUIET) render()
  }

  /** 镜像 SelectionStore.note：重选即清答错态 */
  function noteSelect (key, value, sid) {
    if (!TRACKED.has(key)) return
    if (state.wrongOn === sid) state.wrongOn = null
  }

  /** 取一个热区「写入了哪个被跟踪的键」——用于把选中态画出来 */
  function writtenKey (h) {
    var a = h.action
    switch (a.type) {
      case 'storageAndToast':
      case 'setStorageAndToast':
        return a.storageKey ? { key: a.storageKey, value: a.storageValue == null ? 'true' : a.storageValue } : null
      case 'storageAndNavigate':
        return a.storageKey ? { key: a.storageKey, value: a.storageValue == null ? a.target : a.storageValue } : null
      case 'conditionalStorageNavigate':
        return a.storageKey ? { key: a.storageKey, value: a.defaultValue == null ? 'true' : a.defaultValue } : null
      case 'storage':
        var first = (a.storage || [])[0]
        return first ? { key: first.key, value: first.value } : null
      default:
        return null
    }
  }

  // ── 渲染 ────────────────────────────────────────────────────────────────
  var showRects = false
  var QUIET = false   // 自检时关闭逐次渲染，323 次 DOM 重建没必要
  var EDIT_MODE = false
  var sel = null            // { screen, hotspot }
  var dirty = {}            // 待保存的坐标：{ screenId: { hotspotId: {x,y,width,height} } }
  var dirtyDel = {}         // 待删除的热区：{ screenId: [hotspotId] }

  var r3 = function (v) { return Math.round(v * 1000) / 1000 }
  var clamp = function (v, lo, hi) { return Math.min(hi, Math.max(lo, v)) }

  function applyRect (node, h) {
    node.style.left = pct(h.x)
    node.style.top = pct(h.y)
    node.style.width = pct(h.width)
    node.style.height = pct(h.height)
  }

  function render () {
    var s = stack[stack.length - 1]

    // 记录访问
    if (state.visited.indexOf(s.id) < 0) { state.visited.push(s.id); persist() }

    // 画框
    var phone = $('#phone')
    phone.style.setProperty('--aspect', s.w + ' / ' + s.h)
    $('#shot').src = data.imgBase + s.image
    $('#shot').alt = s.id

    // 热区层 + 选中徽标
    var layer = $('#hotspots')
    var marks = $('#marks')
    layer.innerHTML = ''
    marks.innerHTML = ''
    var oob = oobSet(s)

    s.hotspots.forEach(function (h) {
      var selected = EDIT_MODE && sel && sel.screen === s.id && sel.hotspot === h.id
      var node = el('div', 'hs' + (oob[h.id] ? ' oob' : '') + (selected ? ' selected' : ''))
      node.dataset.hs = h.id
      applyRect(node, h)
      node.appendChild(el('span', 'hs-label', h.label + ' · ' + h.action.type))
      node.title = h.label + ' · ' + h.action.type +
        (h.action.target ? ' → ' + h.action.target : '') +
        (h.action.message ? '  「' + h.action.message + '」' : '')

      if (EDIT_MODE) {
        // 编辑模式：拖拽移动 + 右下角改大小，点击不再执行动作
        var grip = el('div', 'grip')
        node.appendChild(grip)
        node.addEventListener('pointerdown', function (ev) { beginDrag(ev, s, h, node, false) })
        grip.addEventListener('pointerdown', function (ev) { ev.stopPropagation(); beginDrag(ev, s, h, node, true) })
        node.addEventListener('click', function (ev) { ev.stopPropagation(); selectHotspot(s, h) })
      } else {
        node.addEventListener('click', function (ev) {
          ev.stopPropagation()
          var mark = s.id + '/' + h.id
          if (state.clicked.indexOf(mark) < 0) { state.clicked.push(mark); persist() }
          execute(h.action, h, s.id)
        })
      }
      layer.appendChild(node)

      // 选中态：镜像 SelectionRing
      var wk = writtenKey(h)
      if (wk && TRACKED.has(wk.key) && S.get(wk.key) === wk.value) {
        var wrong = state.wrongOn === s.id
        var box = el('div', 'mark' + (wrong ? ' wrong' : ''))
        box.style.left = pct(h.x)
        box.style.top = pct(h.y)
        box.style.width = pct(h.width)
        box.style.height = pct(h.height)
        box.appendChild(el('span', 'badge', wrong ? '✕' : '✓'))
        marks.appendChild(box)
      }
    })

    $('#cur-label').textContent = s.id + '  ' + s.route
    renderSidebar(s)
    renderInspector(s)
    renderStore()
    renderLog()
    if (EDIT_MODE) updateEditPanel()
  }

  function renderSidebar (cur) {
    var list = $('#screen-list')
    list.innerHTML = ''
    screens.forEach(function (s) {
      var node = el('div', 'screen-item' + (s.id === cur.id ? ' active' : '') +
        (state.visited.indexOf(s.id) >= 0 ? ' visited' : '') +
        (diagCache[s.id].length ? ' warn' : ''))
      node.appendChild(el('span', 'sid', s.id))
      node.appendChild(el('span', 'n', s.hotspots.length))
      node.title = s.route + (diagCache[s.id].length ? ' · 诊断 ' + diagCache[s.id].length + ' 条' : '')
      node.addEventListener('click', function () {
        stack = [s]
        state.wrongOn = null
        addLog('⇢', '直接跳到 ' + s.id)
        render()
      })
      list.appendChild(node)
    })

    var totalIssues = screens.reduce(function (n, s) { return n + diagCache[s.id].length }, 0)
    var stats = $('#side-stats')
    stats.innerHTML =
      '屏幕 <b>' + state.visited.length + '/' + screens.length + '</b><br>' +
      '热区已点 <b>' + state.clicked.length + '/' + TOTAL_HS + '</b><br>' +
      '结构诊断 <b>' + totalIssues + '</b> 条<br>' +
      '<span style="color:#8b8275">数据生成 ' + (data.generatedAt || '').replace('T', ' ').slice(0, 16) + '</span>'
    $('#screen-count').textContent = screens.length
  }

  function renderInspector (s) {
    var info = $('#cur-info')
    info.innerHTML = ''
    var rows = [
      ['id', s.id],
      ['route', s.route],
      ['热区', s.hotspots.length + ' 个'],
      ['尺寸', s.w + '×' + s.h]
    ]
    rows.forEach(function (r) {
      var row = el('div', 'row')
      row.appendChild(el('span', 'k', r[0]))
      row.appendChild(el('span', 'v', r[1]))
      info.appendChild(row)
    })

    var crumb = $('#crumb')
    crumb.innerHTML = ''
    stack.forEach(function (x, i) {
      var sp = el('span', i === stack.length - 1 ? 'cur' : '', x.id)
      crumb.appendChild(sp)
      if (i < stack.length - 1) crumb.appendChild(document.createTextNode(' › '))
    })

    var diag = $('#diag')
    diag.innerHTML = ''
    if (!diagCache[s.id].length) {
      diag.appendChild(el('div', 'diag-ok', '✓ 无越界 / 无重复 / 目标可解析'))
    } else {
      diagCache[s.id].forEach(function (t) { diag.appendChild(el('div', 'diag-bad', '▲ ' + t)) })
    }
  }

  function renderStore () {
    var box = $('#store')
    box.innerHTML = ''
    var keys = Object.keys(state.store).sort()
    if (!keys.length) {
      box.appendChild(el('div', 'empty', '（空 —— 点几个热区看看）'))
      return
    }
    keys.forEach(function (k) {
      var row = el('div', 'key')
      row.title = '点击清空该键'
      row.appendChild(el('span', 'kn', k))
      row.appendChild(el('span', 'kv2', '= ' + state.store[k]))
      row.addEventListener('click', function () {
        S.del(k)
        addLog('×', '手动清空 ' + k)
        render()
      })
      box.appendChild(row)
    })
  }

  function renderLog () {
    var box = $('#log')
    box.innerHTML = ''
    if (!logEntries.length) {
      box.appendChild(el('div', 'empty', '（空）'))
      return
    }
    logEntries.forEach(function (e) {
      var row = el('div', 'entry')
      row.appendChild(el('span', 'sid', e.screen + ' '))
      row.appendChild(el('span', 'txt' + (e.kind === '·' ? ' toast' : ''), e.kind + ' ' + e.text))
      box.appendChild(row)
    })
  }

  // ── 编辑模式 ────────────────────────────────────────────────────────────
  function beginDrag (ev, s, h, node, isResize) {
    if (ev.button !== 0) return
    ev.preventDefault()
    var stage = $('#hotspots').getBoundingClientRect()
    var start = { px: ev.clientX, py: ev.clientY, x: h.x, y: h.y, w: h.width, hh: h.height }
    var moved = false
    sel = { screen: s.id, hotspot: h.id }

    function onMove (e) {
      var dx = (e.clientX - start.px) / stage.width * 100
      var dy = (e.clientY - start.py) / stage.height * 100
      if (Math.abs(dx) > 0.03 || Math.abs(dy) > 0.03) moved = true
      if (isResize) {
        h.width = clamp(r3(start.w + dx), 0.3, 100 - h.x)
        h.height = clamp(r3(start.hh + dy), 0.3, 100 - h.y)
      } else {
        h.x = clamp(r3(start.x + dx), 0, 100 - h.width)
        h.y = clamp(r3(start.y + dy), 0, 100 - h.height)
      }
      applyRect(node, h)
      updateEditPanel(s, h)
    }
    function onUp () {
      document.removeEventListener('pointermove', onMove)
      document.removeEventListener('pointerup', onUp)
      if (moved) markDirty(s, h)
    }
    document.addEventListener('pointermove', onMove)
    document.addEventListener('pointerup', onUp)
  }

  function selectHotspot (s, h) {
    sel = { screen: s.id, hotspot: h.id }
    render()
  }

  function markDirty (s, h) {
    dirty[s.id] = dirty[s.id] || {}
    dirty[s.id][h.id] = { x: h.x, y: h.y, width: h.width, height: h.height }
    updateEditPanel(s, h)
  }

  function dirtyCount () {
    var n = 0
    Object.keys(dirty).forEach(function (k) { n += Object.keys(dirty[k]).length })
    Object.keys(dirtyDel).forEach(function (k) { n += dirtyDel[k].length })
    return n
  }

  function updateEditPanel (s, h) {
    var box = $('#edit-panel')
    if (!box) return
    var s2 = s || (sel && byId[sel.screen]) || stack[stack.length - 1]
    var h2 = h || (sel && byId[sel.screen] && byId[sel.screen].hotspots.filter(function (x) { return x.id === sel.hotspot })[0])
    box.innerHTML = ''

    if (!h2) {
      box.appendChild(el('div', 'empty', '点画面里的任一热区开始编辑'))
    } else {
      box.appendChild(el('div', 'edit-name', h2.id))
      box.appendChild(el('div', 'edit-sub', h2.label + ' · ' + h2.action.type))
      var fields = [['x', 'x'], ['y', 'y'], ['w', 'width'], ['h', 'height']]
      var grid = el('div', 'edit-grid')
      fields.forEach(function (f) {
        var wrap = el('div', 'edit-field')
        wrap.appendChild(el('span', 'k', f[0]))
        var inp = document.createElement('input')
        inp.type = 'number'
        inp.step = '0.001'
        inp.value = h2[f[1]]
        inp.addEventListener('change', function () {
          var v = parseFloat(inp.value)
          if (isNaN(v)) { inp.value = h2[f[1]]; return }
          if (f[1] === 'width') h2.width = clamp(r3(v), 0.3, 100 - h2.x)
          else if (f[1] === 'height') h2.height = clamp(r3(v), 0.3, 100 - h2.y)
          else if (f[1] === 'x') h2.x = clamp(r3(v), 0, 100 - h2.width)
          else h2.y = clamp(r3(v), 0, 100 - h2.height)
          markDirty(s2, h2)
          render()
        })
        wrap.appendChild(inp)
        grid.appendChild(wrap)
      })
      box.appendChild(grid)

      var delBtn = el('button', 'btn btn-sm', '删除该热区')
      delBtn.type = 'button'
      delBtn.addEventListener('click', function () {
        s2.hotspots = s2.hotspots.filter(function (x) { return x.id !== h2.id })
        dirtyDel[s2.id] = dirtyDel[s2.id] || []
        if (dirtyDel[s2.id].indexOf(h2.id) < 0) dirtyDel[s2.id].push(h2.id)
        if (dirty[s2.id]) delete dirty[s2.id][h2.id]
        sel = null
        render()
      })
      box.appendChild(delBtn)
    }

    var n = dirtyCount()
    box.appendChild(el('div', 'edit-status', n ? ('待保存 ' + n + ' 处改动') : '暂无改动'))

    var save = el('button', 'btn btn-primary btn-sm', '保存到仓库')
    save.type = 'button'
    save.disabled = !n
    save.addEventListener('click', saveEdits)
    box.appendChild(save)

    var discard = el('button', 'btn btn-sm', '放弃改动')
    discard.type = 'button'
    discard.addEventListener('click', function () { location.reload() })
    box.appendChild(discard)

    var st = el('div', 'edit-status')
    st.id = 'edit-status'
    box.appendChild(st)
  }

  function saveEdits () {
    var st = $('#edit-status')
    if (st) st.textContent = '正在写入并重新生成…'
    fetch('/api/save', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ overrides: dirty, deletions: dirtyDel })
    }).then(function (r) { return r.json() }).then(function (j) {
      if (!j.ok) { if (st) st.textContent = '保存失败：' + (j.error || '未知错误'); return }
      dirty = {}
      dirtyDel = {}
      if (st) st.textContent = '已保存，正在刷新…'
      setTimeout(function () { location.reload() }, 800)
    }).catch(function (e) {
      if (st) st.textContent = '保存失败：' + e.message
    })
  }

  // ── 交互绑定 ────────────────────────────────────────────────────────────
  $('#btn-rects').addEventListener('click', function () {
    showRects = !showRects
    document.body.classList.toggle('rects', showRects)
    this.classList.toggle('on', showRects)
    this.textContent = showRects ? '隐藏热区' : '显示热区'
  })

  $('#btn-reset').addEventListener('click', function () {
    state = { store: {}, clicked: [], visited: [], wrongOn: null }
    logEntries = []
    stack = [byId[data.startScreen] || screens[0]]
    persist()
    toast('已重置')
    render()
  })

  document.addEventListener('keydown', function (e) {
    if (EDIT_MODE && sel && e.key.indexOf('Arrow') === 0) {
      var s = byId[sel.screen]
      var h = s && s.hotspots.filter(function (x) { return x.id === sel.hotspot })[0]
      if (h) {
        e.preventDefault()
        var step = e.shiftKey ? 1 : 0.1
        if (e.key === 'ArrowLeft') h.x = clamp(r3(h.x - step), 0, 100 - h.width)
        if (e.key === 'ArrowRight') h.x = clamp(r3(h.x + step), 0, 100 - h.width)
        if (e.key === 'ArrowUp') h.y = clamp(r3(h.y - step), 0, 100 - h.height)
        if (e.key === 'ArrowDown') h.y = clamp(r3(h.y + step), 0, 100 - h.height)
        markDirty(s, h)
        render()
      }
      return
    }
    if (e.key === 'ArrowLeft' || e.key === 'Backspace') {
      e.preventDefault()
      if (back()) { addLog('←', '键盘返回'); render() }
    } else if (e.key === 'h' || e.key === 'H') {
      $('#btn-rects').click()
    }
  })

  // ── 自动巡检：把每个热区都点一次 ────────────────────────────────────────
  // 为什么放在页面里而不是写成一个独立脚本：它要跑的就是这份渲染后的真实逻辑，
  // 换个实现去测等于测了个影子。地址栏加 ?selftest=1 即触发，结果写进 DOM。
  var NAV_TYPES = {
    navigate: 1, storageAndNavigate: 1, conditionalStorageNavigate: 1,
    setDefaultsAndNavigate: 1, conditionalJump: 1
  }

  function runSelfTest () {
    var savedStore = JSON.stringify(state.store)
    var report = { total: 0, ok: 0, errors: [], noEffect: [], missingKey: [], problems: [] }
    QUIET = true
    problems = []

    screens.forEach(function (s) {
      s.hotspots.forEach(function (h) {
        report.total++
        var before = JSON.stringify(state.store)
        var beforeTop = stack[stack.length - 1].id
        // back 需要一个可回退的栈，否则「空栈返回」会被误判成无反馈
        stack = h.action.type === 'back' ? [screens[0], s] : [s]
        lastToast = null
        try {
          execute(h.action, h, s.id)
          var after = JSON.stringify(state.store)
          var found = stack.some(function (x) { return x.id !== s.id }) || stack[stack.length - 1].id !== beforeTop
          var wrote = after !== before
          var feedback = wrote || found || lastToast !== null || state.wrongOn === s.id

          // 写键类动作却根本没配 storageKey → 配置缺字段，点了等于没点
          var needsKey = /Storage/.test(h.action.type)
          if (needsKey && !h.action.storageKey && !(h.action.storage && h.action.storage.length)) {
            report.missingKey.push(s.id + '/' + h.id + ' (' + h.action.type + ')')
          }
          if (NAV_TYPES[h.action.type] && !found) {
            report.noEffect.push(s.id + '/' + h.id + ' (' + h.action.type + ' → ' + (h.action.target || '无 target') + ')')
          } else if (!feedback) {
            report.noEffect.push(s.id + '/' + h.id + ' (' + h.action.type + ')')
          } else {
            report.ok++
          }
        } catch (e) {
          report.errors.push(s.id + '/' + h.id + ': ' + e.message)
        }
      })
    })

    report.problems = problems.slice()
    state.store = JSON.parse(savedStore)
    QUIET = false

    var lines = []
    lines.push('总热区 ' + report.total + ' · 有反馈 ' + report.ok +
      ' · 抛异常 ' + report.errors.length +
      ' · 无反馈 ' + report.noEffect.length +
      ' · 缺 storageKey ' + report.missingKey.length +
      ' · 运行期问题 ' + report.problems.length)
    ;[['抛异常', report.errors], ['无反馈', report.noEffect], ['缺 storageKey', report.missingKey], ['运行期问题', report.problems]]
      .forEach(function (pair) {
        if (!pair[1].length) return
        lines.push('')
        lines.push('[' + pair[0] + ']')
        pair[1].forEach(function (t) { lines.push('  - ' + t) })
      })

    var pre = document.createElement('pre')
    pre.id = 'selftest-report'
    pre.style.cssText = 'position:fixed;inset:0;z-index:999;overflow:auto;background:#fff;color:#111;' +
      'padding:24px;font:12px/1.7 ui-monospace,Consolas,monospace;white-space:pre-wrap'
    pre.textContent = 'SELFTEST-BEGIN\n' + lines.join('\n') + '\nSELFTEST-END'
    document.body.appendChild(pre)
    document.title = 'SELFTEST ' + report.ok + '/' + report.total
    return report
  }

  // ── 命中测试：热区真的能被鼠标点到吗 ────────────────────────────────────
  // 为什么单独一条：程序化 element.click() 不经过浏览器的命中测试，
  // 所以「上层有个透明 div 把点击全吞了」这种 bug，功能自检完全发现不了。
  // 这里用 elementFromPoint 逐屏逐热区问一句：这个坐标上，最顶层的元素是谁？
  function runHitTest () {
    var savedStack = stack.slice()
    var fails = []
    var tested = 0
    var clipped = 0

    screens.forEach(function (s) {
      stack = [s]
      render()
      s.hotspots.forEach(function (h) {
        var node = $('#hotspots').querySelector('[data-hs="' + h.id + '"]')
        if (!node) { fails.push(s.id + '/' + h.id + ' 节点不存在'); return }
        var r = node.getBoundingClientRect()
        if (r.width < 1 || r.height < 1) { fails.push(s.id + '/' + h.id + ' 渲染尺寸为 0'); return }
        // 落在屏幕外的那部分点不到，取矩形与手机画框的交集中心
        var frame = $('#phone').getBoundingClientRect()
        var left = Math.max(r.left, frame.left)
        var right = Math.min(r.right, frame.right)
        var top = Math.max(r.top, frame.top)
        var bottom = Math.min(r.bottom, frame.bottom)
        if (right <= left || bottom <= top) { clipped++; return }  // 整块在屏外，另算
        tested++
        var at = document.elementFromPoint((left + right) / 2, (top + bottom) / 2)
        var host = at && at.closest ? at.closest('.hs') : null
        if (host !== node) {
          var who = at ? (at.id ? '#' + at.id : (at.className || at.tagName)) : 'null'
          fails.push(s.id + '/' + h.id + ' 被挡住，命中到：' + who)
        }
      })
    })

    stack = savedStack
    render()

    var lines = ['热区 ' + tested + ' 个可测 · 命中失败 ' + fails.length + ' · 完全在屏外 ' + clipped]
    if (fails.length) {
      lines.push('')
      fails.forEach(function (t) { lines.push('  - ' + t) })
    }
    var pre = document.createElement('pre')
    pre.id = 'hittest-report'
    pre.style.cssText = 'position:fixed;inset:0;z-index:999;overflow:auto;background:#fff;color:#111;' +
      'padding:24px;font:12px/1.7 ui-monospace,Consolas,monospace;white-space:pre-wrap'
    pre.textContent = 'HITTEST-BEGIN\n' + lines.join('\n') + '\nHITTEST-END'
    document.body.appendChild(pre)
    document.title = 'HITTEST ' + (tested - fails.length) + '/' + tested
    return { tested: tested, fails: fails, clipped: clipped }
  }

  // 直达参数：?screen=jiangxue-scene&rects=1（便于发给别人一个固定视角的链接）
  //            ?click=answer-b,submit-btn 按顺序点一遍（走真实的点击监听，不是直接调 execute）
  var qs = new URLSearchParams(location.search)
  EDIT_MODE = qs.has('edit') && location.protocol === 'http:'
  if (qs.get('screen') && byId[qs.get('screen')]) stack = [byId[qs.get('screen')]]
  if (qs.has('rects') || EDIT_MODE) $('#btn-rects').click()

  if (EDIT_MODE) {
    document.body.classList.add('editing')
    var sec = el('section', 'edit-section')
    sec.appendChild(el('h3', null, '编辑热区'))
    var editBox = el('div')
    editBox.id = 'edit-panel'
    sec.appendChild(editBox)
    var insp = $('#inspector')
    insp.insertBefore(sec, insp.firstChild)
    $('#hint').textContent = '拖动热区移动 · 拖右下角改大小 · 方向键微调（Shift 加速）· 改完点「保存到仓库」'
  } else if (qs.has('edit')) {
    $('#hint').textContent = '编辑模式需要通过本地服务打开：node tools/hotspot-server.mjs'
  }

  render()
  if (EDIT_MODE) updateEditPanel()

  var clickList = (qs.get('click') || '').split(',').filter(Boolean)
  if (clickList.length) {
    clickList.forEach(function (hid) {
      var node = $('#hotspots').querySelector('[data-hs="' + hid + '"]')
      if (node) node.click()
    })
    document.title = 'CLICK ' + clickList.join('>') + ' → ' + stack[stack.length - 1].id
  }

  if (location.search.indexOf('selftest') >= 0) runSelfTest()
  if (location.search.indexOf('hittest') >= 0) runHitTest()
})()
