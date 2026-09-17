(function () {
  'use strict';

  var intro = document.getElementById('intro');
  var storageKey = 'homepage-quote-intro-seen';
  var preview = new URLSearchParams(window.location.search).get('intro') === '1';
  if (!intro || typeof intro.showModal !== 'function' || window.location.hash) return;

  var characters = intro.querySelectorAll('.intro__char');
  if (!characters.length) return;
  try {
    if (!preview && window.sessionStorage.getItem(storageKey) === 'yes') return;
  } catch (error) {
    // The entrance also works when browser storage is unavailable.
  }

  var finished = false;
  var timers = [];
  var reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var revealStart = 500;
  var revealStep = 85;
  var revealDuration = 1100;
  var readingTime = 2200;

  function later(callback, delay) {
    timers.push(window.setTimeout(callback, delay));
  }

  function finish() {
    if (finished) return;
    finished = true;
    timers.forEach(function (timer) { window.clearTimeout(timer); });
    try { window.sessionStorage.setItem(storageKey, 'yes'); } catch (error) {}
    intro.close();
    document.documentElement.classList.remove('intro-open');
    var main = document.getElementById('main');
    if (main) main.focus({ preventScroll: true });
  }

  function play() {
    if (finished) return;
    if (reducedMotion) {
      later(finish, readingTime);
      return;
    }
    intro.style.setProperty('--reveal-duration', revealDuration + 'ms');
    // Give punctuation and the change of line a little breathing room.
    var delay = revealStart;
    var lastDelay = delay;
    var previousLine = null;
    Array.prototype.forEach.call(characters, function (character) {
      if (previousLine && previousLine !== character.parentElement) delay += 380;
      character.style.setProperty('--char-delay', delay + 'ms');
      lastDelay = delay;
      delay += revealStep;
      if (character.textContent === '，') delay += 120;
      if (character.textContent === '。') delay += 220;
      previousLine = character.parentElement;
    });
    intro.classList.add('intro--playing');
    var completeAt = lastDelay + revealDuration;
    later(function () {
      intro.classList.add('intro--leaving');
      later(finish, 900);
    }, completeAt + readingTime);
  }

  intro.querySelector('.intro__skip').addEventListener('click', finish);
  intro.addEventListener('cancel', function (event) { event.preventDefault(); finish(); });
  intro.addEventListener('keydown', function (event) {
    if (event.key === 'Enter') { event.preventDefault(); finish(); }
  });
  window.addEventListener('hashchange', function () { if (intro.open) finish(); });

  intro.showModal();
  document.documentElement.classList.add('intro-open');
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', play, { once: true });
  } else {
    play();
  }
}());
