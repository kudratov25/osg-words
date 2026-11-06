// OSG landing page: theme toggle, word card, reveal-on-scroll. No dependencies.
(function () {
  var root = document.documentElement
  var KEY = 'osg_site_theme'

  // ---- theme ----
  var meta = document.querySelector('meta[name="theme-color"]')
  function applyTheme(t) {
    root.dataset.theme = t
    if (meta) meta.setAttribute('content', t === 'light' ? '#EEF2F9' : '#0B0E14')
  }
  applyTheme(root.dataset.theme || 'dark')
  var toggle = document.getElementById('theme-toggle')
  if (toggle) {
    toggle.addEventListener('click', function () {
      var next = root.dataset.theme === 'light' ? 'dark' : 'light'
      applyTheme(next)
      try { localStorage.setItem(KEY, next) } catch (e) {}
    })
  }
  var mq = window.matchMedia && matchMedia('(prefers-color-scheme: light)')
  if (mq && mq.addEventListener) {
    mq.addEventListener('change', function (e) {
      var saved = null
      try { saved = localStorage.getItem(KEY) } catch (err) {}
      if (!saved) applyTheme(e.matches ? 'light' : 'dark')
    })
  }

  // ---- word card (real words from the app's word list) ----
  var WORDS = [
    ['der', 'Bahnhof', 'train station', 'Der Bahnhof ist ganz in der Nähe.', 'Travel', 'beginner'],
    ['die', 'Rechnung', 'bill / receipt', 'Kann ich die Rechnung haben?', 'Daily Life', 'beginner'],
    [null, 'erledigen', 'to complete / take care of', 'Ich muss meine Arbeit erledigen.', 'Work', 'intermediate'],
    ['die', 'Küche', 'kitchen', 'Wir kochen zusammen in der Küche.', 'Daily Life', 'beginner'],
    ['der', 'Termin', 'appointment', 'Ich habe morgen einen Termin.', 'Daily Life', 'beginner'],
    ['das', 'Brot', 'bread', 'Ich kaufe frisches Brot.', 'Food', 'beginner'],
    ['der', 'Schlüssel', 'key', 'Wo ist mein Schlüssel?', 'Daily Life', 'beginner'],
    ['die', 'Besprechung', 'meeting', 'Die Besprechung beginnt um zehn Uhr.', 'Work', 'intermediate'],
  ]
  var i = 0
  var $ = function (id) { return document.getElementById(id) }
  var word = $('f-word'), reveal = $('f-reveal'), show = $('f-show'), next = $('f-next')
  function esc(s) { return s.replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c] }) }
  function render() {
    var w = WORDS[i]
    word.innerHTML = (w[0] ? '<span class="art art-' + w[0] + '">' + w[0] + '</span> ' : '') + esc(w[1])
    $('f-tr').textContent = w[2]
    $('f-ex').textContent = w[3]
    $('f-cat').textContent = w[4]
    $('f-level').textContent = w[5]
    reveal.hidden = true
    show.disabled = false
    show.textContent = 'Show meaning'
  }
  if (word && reveal && show && next) {
    show.addEventListener('click', function () {
      reveal.hidden = false
      show.disabled = true
      show.textContent = 'Got it?'
    })
    next.addEventListener('click', function () {
      i = (i + 1) % WORDS.length
      render()
    })
    render()
  }

  // ---- reveal on scroll ----
  var items = document.querySelectorAll('.reveal-up')
  if (!('IntersectionObserver' in window)) {
    items.forEach(function (el) { el.classList.add('in') })
  } else {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target) }
      })
    }, { rootMargin: '0px 0px -8% 0px' })
    items.forEach(function (el) { io.observe(el) })
  }

  // ---- phone mockup: plays through a day (08:00 -> 12:00 -> 18:00 -> reminder) ----
  // Each word notification arrives and the widget switches to the same word
  // at that moment - exactly what the app does. Off with reduced motion
  // (static 12:00 picture stays), paused when off screen or tab hidden.
  ;(function phoneDay() {
    var stage = document.querySelector('.phone-stage')
    var clock = $('ph-clock'), widget = $('ph-widget'), list = $('ph-notifs'), next = $('ph-next'), count = $('ph-count')
    if (!stage || !clock || !widget || !list) return
    if (window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches) return

    var DAY = [
      { time: '08:00', kind: 'word', art: 'der', word: 'Schlüssel', tr: 'key', ex: 'Wo ist mein Schlüssel?', next: '12:00', n: 1 },
      { time: '12:00', kind: 'word', art: 'die', word: 'Besprechung', tr: 'meeting', ex: 'Die Besprechung beginnt um zehn Uhr.', next: '18:00', n: 2 },
      { time: '18:00', kind: 'word', art: 'das', word: 'Brot', tr: 'bread', ex: 'Ich kaufe frisches Brot.', next: '08:00', n: 3 },
      { time: '19:00', kind: 'reminder', title: '🏃 Evening run', body: "Today's goal: 5 km, easy pace", next: '08:00', n: 3 },
    ]
    var STEP_MS = 3400
    // The phone mockup is shorter on small screens: 2 notifications fit there, 3 elsewhere.
    var small = window.matchMedia ? matchMedia('(max-width: 720px)') : null
    function maxVisible() { return small && small.matches ? 2 : 3 }
    var step = 0, timer = null, visible = false

    function el(tag, cls, text) {
      var e = document.createElement(tag)
      if (cls) e.className = cls
      if (text != null) e.textContent = text
      return e
    }
    function retrigger(node, cls) {
      node.classList.remove(cls)
      void node.offsetWidth // restart the CSS animation
      node.classList.add(cls)
    }
    function setText(node, text) {
      if (!node || node.textContent === text) return
      node.textContent = text
      retrigger(node, node === clock ? 'tick' : 'bump')
    }
    function notification(item) {
      var n = el('div', 'notif enter' + (item.kind === 'reminder' ? ' reminder' : ''))
      var head = el('div', 'n-head')
      head.appendChild(el('span', 'n-app'))
      head.appendChild(document.createTextNode('OSG'))
      head.appendChild(el('span', 'n-time', 'now'))
      n.appendChild(head)
      if (item.kind === 'word') {
        n.appendChild(el('strong', null, '🇩🇪 ' + item.art + ' ' + item.word))
        n.appendChild(el('div', 'n-body', item.tr + ' · ' + item.ex))
      } else {
        n.appendChild(el('strong', null, item.title))
        n.appendChild(el('div', 'n-body', item.body))
      }
      return n
    }
    function showWord(item) {
      var body = widget.querySelector('.w-body')
      body.querySelector('.w-title').textContent = '🇩🇪 ' + item.art + ' ' + item.word
      body.querySelector('.w-tr').textContent = item.tr
      body.querySelector('.w-ex').textContent = item.ex
      retrigger(widget, 'swap')
    }
    function arrive(item) {
      setText(clock, item.time)
      // previous notifications: stamp their time, push back, drop the oldest
      var current = list.querySelectorAll('.notif:not(.leave)')
      current.forEach(function (n, i) {
        var t = n.querySelector('.n-time')
        if (t && t.textContent === 'now') t.textContent = n.dataset.time || ''
        n.classList.remove('enter', 'newest')
        var age = current.length - i // 1 = the one just before the new arrival
        n.classList.toggle('older', age === 1)
        n.classList.toggle('oldest', age >= 2)
        if (age >= maxVisible()) {
          n.classList.add('leave')
          setTimeout(function () { n.remove() }, 600)
        }
      })
      var n = notification(item)
      n.dataset.time = item.time
      list.appendChild(n)
      if (item.kind === 'word') showWord(item)
      setText(next, item.next)
      setText(count, item.n + ' of 3 words')
    }
    // Night -> next morning: clear the screen, clock to 07:59. Like the real
    // widget, it keeps showing yesterday's last word until 08:00.
    function reset() {
      list.querySelectorAll('.notif').forEach(function (n) {
        n.classList.add('leave')
        setTimeout(function () { n.remove() }, 600)
      })
      setText(clock, '07:59')
      setText(count, '0 of 3 words')
      setText(next, '08:00')
    }
    function tick() {
      if (step === 0) {
        reset()
        timer = setTimeout(function () { arrive(DAY[0]); step = 1; schedule() }, 700)
        return
      }
      arrive(DAY[step])
      step = (step + 1) % DAY.length
      schedule()
    }
    function schedule() {
      clearTimeout(timer)
      if (visible && !document.hidden) timer = setTimeout(tick, step === 0 ? STEP_MS + 1200 : STEP_MS)
    }
    function setRunning() {
      clearTimeout(timer)
      if (visible && !document.hidden) timer = setTimeout(tick, 900)
    }

    // Take over from the static markup: start the day at 08:00.
    stage.classList.add('animated')
    list.innerHTML = ''
    showWord(DAY[2]) // yesterday's 18:00 word
    reset()

    if ('IntersectionObserver' in window) {
      new IntersectionObserver(function (entries) {
        visible = entries[0].isIntersecting
        setRunning()
      }, { threshold: 0.25 }).observe(stage)
    } else {
      visible = true
      setRunning()
    }
    document.addEventListener('visibilitychange', setRunning)
  })()

  // ---- cursor parallax on the hero phone ----
  // Phone tilts toward the cursor (max ~9deg), the two floating cards drift
  // at different depths, a light glare follows the cursor across the screen.
  // Only for a real mouse/trackpad, not with reduced motion; eased with
  // requestAnimationFrame and idle (no frames) when nothing changes.
  ;(function parallax() {
    var stage = document.querySelector('.phone-stage')
    if (!stage || !window.matchMedia) return
    if (!matchMedia('(hover: hover) and (pointer: fine)').matches) return
    if (matchMedia('(prefers-reduced-motion: reduce)').matches) return
    stage.classList.add('tilt')

    var MAX_RX = 7, MAX_RY = 9
    var target = { x: 0, y: 0, glare: 0 }, cur = { x: 0, y: 0, glare: 0 }
    var gx = 50, gy = 30, frame = 0

    function onMove(e) {
      var r = stage.getBoundingClientRect()
      if (r.bottom < 0 || r.top > innerHeight) return
      var cx = r.left + r.width / 2, cy = r.top + r.height / 2
      // -1..1 across roughly the hero's width/height around the phone
      target.x = Math.max(-1, Math.min(1, (e.clientX - cx) / (innerWidth * 0.5)))
      target.y = Math.max(-1, Math.min(1, (e.clientY - cy) / (innerHeight * 0.6)))
      var near = Math.abs(e.clientX - cx) < r.width * 1.6 && Math.abs(e.clientY - cy) < r.height * 0.9
      target.glare = near ? 1 : 0.35
      var phone = stage.querySelector('.screen').getBoundingClientRect()
      gx = ((e.clientX - phone.left) / phone.width) * 100
      gy = ((e.clientY - phone.top) / phone.height) * 100
      kick()
    }
    function onLeave() { target.x = 0; target.y = 0; target.glare = 0; kick() }
    function kick() { if (!frame) frame = requestAnimationFrame(step) }
    function step() {
      frame = 0
      var k = 0.12 // easing: follow ~12% of the remaining distance per frame
      cur.x += (target.x - cur.x) * k
      cur.y += (target.y - cur.y) * k
      cur.glare += (target.glare - cur.glare) * k
      stage.style.setProperty('--ry', (cur.x * MAX_RY).toFixed(2) + 'deg')
      stage.style.setProperty('--rx', (-cur.y * MAX_RX).toFixed(2) + 'deg')
      stage.style.setProperty('--px', cur.x.toFixed(3))
      stage.style.setProperty('--py', cur.y.toFixed(3))
      stage.style.setProperty('--gx', gx.toFixed(1) + '%')
      stage.style.setProperty('--gy', gy.toFixed(1) + '%')
      stage.style.setProperty('--glare', (cur.glare * 0.9).toFixed(3))
      var moving = Math.abs(target.x - cur.x) > 0.001 || Math.abs(target.y - cur.y) > 0.001 || Math.abs(target.glare - cur.glare) > 0.005
      if (moving) kick()
    }
    window.addEventListener('pointermove', onMove, { passive: true })
    document.documentElement.addEventListener('pointerleave', onLeave)
    window.addEventListener('blur', onLeave)
  })()

  var y = $('year')
  if (y) y.textContent = String(new Date().getFullYear())
})()
