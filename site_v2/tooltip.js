(function () {
  var tip = document.getElementById('tip');
  if (!tip) return;
  function show(el, x, y) {
    tip.textContent = el.getAttribute('data-tip');
    tip.hidden = false;
    var r = tip.getBoundingClientRect();
    var left = Math.min(Math.max(8, x + 14), window.innerWidth - r.width - 8);
    var top = y + 18;
    if (top + r.height > window.innerHeight - 8) top = y - r.height - 12;
    tip.style.left = left + 'px';
    tip.style.top = Math.max(8, top) + 'px';
  }
  function hide() { tip.hidden = true; }
  document.addEventListener('mousemove', function (ev) {
    var el = ev.target.closest ? ev.target.closest('[data-tip]') : null;
    if (el) show(el, ev.clientX, ev.clientY); else hide();
  });
  document.addEventListener('focusin', function (ev) {
    var el = ev.target.closest ? ev.target.closest('[data-tip]') : null;
    if (el) { var b = el.getBoundingClientRect(); show(el, b.left + b.width / 2, b.bottom - 10); }
  });
  document.addEventListener('focusout', hide);
  document.addEventListener('scroll', hide, { passive: true });
})();
