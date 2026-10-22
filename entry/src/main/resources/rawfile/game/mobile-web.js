(() => {
  const contexts = new Set();
  for (const name of ['AudioContext', 'webkitAudioContext']) {
    const NativeContext = window[name];
    if (!NativeContext) continue;
    window[name] = class extends NativeContext {
      constructor(...args) {
        super(...args);
        contexts.add(this);
      }
    };
  }

  function resumeAudio() {
    for (const context of contexts) {
      if (context.state === 'suspended') context.resume().catch(() => {});
    }
  }

  const music = new Audio('bgm.mp3');
  music.id = 'town-bgm';
  music.hidden = true;
  music.loop = true;
  music.preload = 'auto';
  music.volume = 0.65;
  document.addEventListener('DOMContentLoaded', () => document.body.appendChild(music), { once: true });
  window.__townMusic = music;
  window.__setTownMusicVolume = value => {
    music.volume = Math.max(0, Math.min(1, value));
    if (music.volume > 0 && !music.paused) return;
    if (music.volume > 0 && document.hasFocus()) startAudio();
  };

  function startAudio() {
    resumeAudio();
    if (music.volume > 0 && music.paused) music.play().catch(() => {});
  }

  window.__resumeGodotAudio = startAudio;

  for (const type of ['pointerdown', 'touchstart', 'keydown', 'click']) {
    document.addEventListener(type, startAudio, { capture: true, passive: true });
  }

  function setupLandscape() {
    const prompt = document.createElement('div');
    prompt.id = 'landscape-prompt';
    prompt.innerHTML = '<div><strong>请横屏体验</strong><p>旋转手机，或点击下方按钮切换横屏。</p><button type="button">切换横屏</button></div>';
    document.body.appendChild(prompt);

    function update() {
      prompt.hidden = innerWidth >= innerHeight ||
        (!matchMedia('(pointer: coarse)').matches && innerWidth > 700);
    }
    prompt.querySelector('button').addEventListener('click', async () => {
      startAudio();
      try {
        if (!document.fullscreenElement && document.documentElement.requestFullscreen) {
          await document.documentElement.requestFullscreen();
        }
        if (screen.orientation && screen.orientation.lock) {
          await screen.orientation.lock('landscape');
        }
      } catch (_) {
      }
      update();
    });
    addEventListener('resize', update);
    addEventListener('orientationchange', update);
    update();
  }

  document.addEventListener('DOMContentLoaded', setupLandscape, { once: true });
})();
