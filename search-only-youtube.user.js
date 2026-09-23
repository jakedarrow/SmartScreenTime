// ==UserScript==
// @name         Search-Only YouTube
// @namespace    https://github.com/jakedarrow/search-only-youtube
// @version      1.3.1
// @description  Turns YouTube into a distraction-free search tool: eliminates feeds, shorts, comments, recommendations, and autoplay countdowns.
// @author       Jake Darrow
// @license      MIT
// @match        *://*.youtube.com/*
// @run-at       document-start
// @grant        none
// @downloadURL  https://raw.githubusercontent.com/jakedarrow/search-only-youtube/main/search-only-youtube.user.js
// @updateURL    https://raw.githubusercontent.com/jakedarrow/search-only-youtube/main/search-only-youtube.user.js
// ==/UserScript==

(function () {
  'use strict';

  // 1. Inject Hardcore Distraction-Free CSS (Desktop & Mobile)
  const css = `
/* ==========================================================================
   Search-Only YouTube: Distraction-Free CSS (Desktop & Mobile)
   ========================================================================== */

/* 1. End-Screen Suggested Video Wall, Overlays & Autonav Countdowns */
.ytp-videowall-still,
.ytp-videowall-still-image,
.ytp-videowall-still-info,
.ytp-videowall-still-list,
.ytp-videowall-still-round-large,
.ytp-show-tiles,
.ytp-endscreen-content,
.ytp-endscreen-paginate,
.ytp-suggestion-set,
.html5-endscreen,
.ytp-ce-element,
.ytp-ce-video,
.ytp-ce-playlist,
.ytp-ce-channel,
.ytp-ce-element-show,
.ytp-ce-covering-overlay,
.ytp-ce-covering-image,
.ytp-ce-shadow,
.endscreen-video-item,
[class*="videowall" i],
[class*="ytp-endscreen" i],
.ytp-upnext,
.ytp-upnext-container,
.ytp-player-content.ytp-upnext,
.ytp-autonav-endscreen-countdown-container,
.ytp-autonav-endscreen-countdown-overlay,
.ytp-autonav-endscreen-upnext-container,
.ytp-autonav-endscreen-upnext-header,
.ytp-autonav-endscreen-upnext-button,
.ytp-autonav-endscreen-button-container,
.ytp-autonav-endscreen-link-container,
.ytp-cairo-refresh-autonav-overlay,
ytm-autonav-endscreen-renderer,
ytm-autonav-bar,
ytm-endscreen-renderer,
ytm-endscreen-item-renderer,
ytm-endscreen-element,
ytm-autonav-endscreen-button-renderer,
ytm-autonav-preview-renderer,
ytm-autonav-countdown-renderer,
ytm-upnext-renderer {
  display: none !important;
  opacity: 0 !important;
  visibility: hidden !important;
  pointer-events: none !important;
  width: 0 !important;
  height: 0 !important;
  max-height: 0 !important;
  max-width: 0 !important;
}

/* 2. Desktop YouTube Clutter, Feeds, Ads & Comments */
#guide,
ytd-mini-guide-renderer,
#guide-button,
#chips-wrapper,
#header #chips,
ytd-feed-filter-chip-bar-renderer,
#voice-search-button,
#buttons ytd-notification-topbar-button-renderer,
#buttons ytd-button-renderer:has(a[href*="upload"]),
#masthead-ad,
ytd-ad-slot-renderer,
.badge-style-type-ad,
ytd-browse[page-subtype="home"] #contents,
ytd-browse[page-subtype="home"] ytd-rich-grid-renderer,
ytd-browse[page-subtype="home"] #primary,
ytd-watch-flexy #secondary,
ytd-watch-flexy #related,
#comments,
ytd-comments,
ytd-item-section-renderer:has(#comments),
ytd-watch-flexy ytd-watch-next-secondary-results-renderer {
  display: none !important;
}

/* 3. Mobile YouTube Clutter, Feeds & Recommendations */
ytm-feed-filter-chip-bar-renderer,
ytm-chip-cloud-renderer,
ytm-chip-cloud-chip-renderer,
.feed-filter-chip-bar-renderer,
ytm-pivot-bar-renderer,
ytm-browse[page-subtype="home"],
ytm-browse ytm-rich-grid-renderer,
ytm-browse ytm-section-list-renderer,
ytm-browse ytm-single-column-browse-results-renderer,
ytm-browse ytm-media-item,
ytm-browse ytm-video-with-context-renderer,
ytm-browse ytm-item-section-renderer,
[tab-identifier="FEwhat_to_watch"],
ytm-app[is-home] ytm-single-column-browse-results-renderer,
ytm-app[is-home] ytm-section-list-renderer,
ytm-app[is-home] ytm-media-item,
body.sst-mobile-home ytm-single-column-browse-results-renderer,
body.sst-mobile-home ytm-section-list-renderer,
body.sst-mobile-home ytm-media-item,
body.sst-mobile-home ytm-video-with-context-renderer,
body.sst-mobile-home lazy-list,
ytm-watch ytm-item-section-renderer[section-identifier="related-items"],
ytm-watch ytm-related-chip-cloud-renderer {
  display: none !important;
}

/* 4. Mobile Comments & Engagement Panels */
ytm-comments-entry-point-header-renderer,
ytm-comments-header-renderer,
ytm-comment-section-renderer,
ytm-comment-thread-renderer,
ytm-compact-comment-renderer,
.ytm-comments-section,
.ytm-comments-entry-point,
[class*="comments-entry-point"],
[class*="comment-entry-point"],
[class*="comment-section"],
[section-identifier="comment-item-section"],
[section-identifier*="comments"],
[target-id*="comments"],
ytm-item-section-renderer:has(ytm-comments-entry-point-header-renderer),
ytm-item-section-renderer:has(ytm-comments-header-renderer),
ytm-item-section-renderer:has([class*="comments-entry-point"]),
ytm-item-section-renderer:has([class*="comment"]),
ytm-engagement-panel-section-list-renderer[target-id="engagement-panel-comments-section"],
ytm-engagement-panel-section-list-renderer:has([class*="comment"]),
ytm-engagement-panel-section-list-renderer:has(ytm-comments-entry-point-header-renderer) {
  display: none !important;
  visibility: hidden !important;
  height: 0 !important;
  max-height: 0 !important;
  opacity: 0 !important;
  pointer-events: none !important;
  margin: 0 !important;
  padding: 0 !important;
}

/* 5. Hard Block All Shorts */
ytd-reel-shelf-renderer,
ytd-reel-item-renderer,
ytd-rich-shelf-renderer[is-shorts],
ytd-rich-section-renderer:has(ytd-reel-shelf-renderer),
ytd-shelf-renderer:has(ytd-reel-shelf-renderer),
ytd-item-section-renderer:has(ytd-reel-shelf-renderer),
ytd-video-renderer:has(a[href*="/shorts/"]),
ytd-grid-video-renderer:has(a[href*="/shorts/"]),
ytd-compact-video-renderer:has(a[href*="/shorts/"]),
a[title="Shorts"],
ytd-guide-entry-renderer:has(a[title="Shorts"]),
ytd-mini-guide-entry-renderer[aria-label="Shorts"],
yt-chip-cloud-chip-renderer:has(yt-formatted-string[title="Shorts"]),
grid-shelf-view-model,
ytm-reel-shelf-renderer,
ytm-reel-item-renderer,
ytm-rich-section-renderer:has(ytm-reel-shelf-renderer),
ytm-video-with-context-renderer:has(a[href*="/shorts/"]),
ytm-media-item:has(a[href*="/shorts/"]),
ytm-pivot-bar-item-renderer:has([aria-label="Shorts"]) {
  display: none !important;
}

  `;

  function injectStyles() {
    const style = document.createElement('style');
    style.id = 'search-only-youtube-style';
    style.textContent = css;
    (document.head || document.documentElement).appendChild(style);
  }

  injectStyles();


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
