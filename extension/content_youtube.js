// Search-Only YouTube: Distraction-Free YouTube Engine & Screen Time Limiter
(function () {
  'use strict';

  function handleNavigation() {
    const path = window.location.pathname;

    // Hard block direct /shorts/ navigation -> redirect to standard watch
    if (path.startsWith('/shorts/')) {
      const id = path.split('/shorts/')[1]?.split('?')[0];
      window.location.replace(id ? `https://www.youtube.com/watch?v=${id}` : 'https://www.youtube.com/');
      return;
    }

    if (path === '/' || path === '') {
      document.body?.classList.add('sst-mobile-home', 'sst-home-view');
      document.documentElement?.classList.add('sst-mobile-home');
      purgeHome();
      focusNativeSearchBar();
    } else {
      document.body?.classList.remove('sst-mobile-home', 'sst-home-view');
      document.documentElement?.classList.remove('sst-mobile-home');
    }

    if (path.includes('/results')) {
      purgeShorts();
    }

    if (path.includes('/watch')) {
      disableAutoplay();
      purgeEndScreenOverlays();
    }
  }

  function purgeHome() {
    if (window.location.pathname !== '/' && window.location.pathname !== '') return;
    document.querySelectorAll(
      'ytm-feed-filter-chip-bar-renderer, ytm-chip-cloud-renderer, ytm-single-column-browse-results-renderer, ytm-section-list-renderer, [tab-identifier="FEwhat_to_watch"], ytm-pivot-bar-renderer, ytd-browse[page-subtype="home"] #contents'
    ).forEach(el => el.remove());
  }

  function purgeShorts() {
    document.querySelectorAll('a[href*="/shorts/"]').forEach(link => {
      link.closest(
        'ytd-video-renderer, ytd-grid-video-renderer, ytd-reel-shelf-renderer, grid-shelf-view-model, ytm-video-with-context-renderer, ytm-media-item'
      )?.remove();
    });
    document.querySelectorAll(
      'ytd-reel-shelf-renderer, ytd-rich-shelf-renderer[is-shorts], grid-shelf-view-model, ytm-reel-shelf-renderer, ytm-reel-item-renderer'
    ).forEach(s => s.remove());
  }

  function purgeEndScreenOverlays() {
    const player = document.querySelector('.html5-video-player');
    if (player) {
      player.classList.remove('ytp-show-tiles', 'ytp-upnext-active');
    }

    // Auto-cancel autoplay countdown on mobile if present
    const mobileCancelBtn = document.querySelector('ytm-autonav-endscreen-renderer button, ytm-autonav-countdown-renderer button');
    if (mobileCancelBtn) {
      mobileCancelBtn.click();
    }

    // Safely remove overlay elements without touching the video player
    document.querySelectorAll(
      '.ytp-videowall-still, .ytp-endscreen-content, .ytp-ce-element, .html5-endscreen, .ytm-endscreen-renderer, [class*="videowall" i], .ytp-suggestion-set, ytm-autonav-endscreen-renderer, ytm-autonav-bar, ytm-autonav-countdown-renderer, .ytp-autonav-endscreen-countdown-container, .ytp-cairo-refresh-autonav-overlay'
    ).forEach(el => {
      if (el && el !== player && !el.contains(player)) {
        el.remove();
      }
    });
  }

  function disableAutoplay() {
    setTimeout(() => {
      const autoplayBtn = document.querySelector('.ytp-autonav-toggle-button[aria-checked="true"]');
      if (autoplayBtn) {
        autoplayBtn.click();
      }
    }, 1000);
  }

  function focusNativeSearchBar() {
    setTimeout(() => {
      const searchInput = document.querySelector('input#search') ||
                          document.querySelector('input.ytSearchboxComponentInput') ||
                          document.querySelector('input[name="search_query"]') ||
                          document.querySelector('.ytm-search-input');
      if (searchInput) {
        searchInput.focus();
      }
    }, 200);
  }

  // Screen Time Limiter Heartbeat & Telemetry (every 5s during active playback)
  function setupPlaybackTelemetry() {
    setInterval(() => {
      if (!window.location.pathname.includes('/watch')) return;
      const video = document.querySelector('video');
      if (video && !video.paused && !video.ended && document.visibilityState === 'visible') {
        try {
          chrome.runtime?.sendMessage?.({
            type: 'PLAYBACK_HEARTBEAT',
            url: window.location.href,
            title: document.title,
            seconds: 5
          });
        } catch (e) {
          // Extension context invalidated or userscript mode - ignore
        }
      }
    }, 5000);
  }

  // End-of-video overlay interceptors
  document.addEventListener('timeupdate', (e) => {
    if (e.target && e.target.tagName === 'VIDEO') {
      const video = e.target;
      if (video.duration && (video.duration - video.currentTime < 15 || video.ended)) {
        purgeEndScreenOverlays();
      }
    }
  }, true);

  document.addEventListener('ended', purgeEndScreenOverlays, true);

  // SPA navigation hooks
  window.addEventListener('yt-navigate-finish', handleNavigation);
  window.addEventListener('ytm-navigate-finish', handleNavigation);
  window.addEventListener('popstate', handleNavigation);

  // MutationObserver for asynchronous dynamic rendering
  new MutationObserver(() => {
    const path = window.location.pathname;
    if (path === '/' || path === '') purgeHome();
    else if (path.includes('/results')) purgeShorts();
    else if (path.includes('/watch')) purgeEndScreenOverlays();
  }).observe(document.documentElement, { childList: true, subtree: true });

  setupPlaybackTelemetry();

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', handleNavigation);
  } else {
    handleNavigation();
  }
})();
