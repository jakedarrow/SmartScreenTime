// ==UserScript==
// @name         Search-Only YouTube
// @namespace    https://github.com/jakedarrow/search-only-youtube
// @version      1.3.0
// @description  Turns YouTube into a distraction-free search tool: eliminates feeds, shorts, comments, recommendations, and autoplay countdowns.
// @author       Jake Darrow
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
       1. Hard Block End-Screen Overlays, Up Next Countdown Cards & Autonav
       ========================================================================== */
    /* Mobile Custom Tags (No leading dot - custom HTML elements) */
    ytm-autonav-endscreen-renderer,
    ytm-autonav-bar,
    ytm-endscreen-renderer,
    ytm-endscreen-item-renderer,
    ytm-endscreen-element,
    ytm-autonav-endscreen-button-renderer,
    ytm-autonav-preview-renderer,
    ytm-autonav-countdown-renderer,
    ytm-upnext-renderer,

    /* Desktop & Mobile Player Classes */
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
    [class*="ytp-upnext" i],
    [class*="autonav-endscreen" i],
    [class*="ytm-endscreen" i],
    [class*="ytp-autonav" i],
    [class*="autonav" i] {
      display: none !important;
      opacity: 0 !important;
      visibility: hidden !important;
      pointer-events: none !important;
      width: 0 !important;
      height: 0 !important;
      max-height: 0 !important;
      max-width: 0 !important;
    }

    /* ==========================================================================
       2. Desktop YouTube Clutter, Feeds, Ads & Comments
       ========================================================================== */
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

    /* ==========================================================================
       3. Mobile YouTube Clutter, Feeds & Recommendations
       ========================================================================== */
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

    /* ==========================================================================
       4. Mobile Comments & Engagement Panels
       ========================================================================== */
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

    /* ==========================================================================
       5. Hard Block All Shorts
       ========================================================================== */
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

  const styleEl = document.createElement('style');
  styleEl.textContent = css;
  (document.head || document.documentElement).appendChild(styleEl);

  // 2. Navigation & DOM Cleaning Engine
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
      killUpNextAndEndScreen();
    }
  }

  function purgeHome() {
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

  // Active exterminator for "Up next in X" cards, end-screen video tiles & autoplay prompts
  function killUpNextAndEndScreen() {
    const player = document.querySelector('.html5-video-player');
    if (player) {
      player.classList.remove('ytp-show-tiles', 'ytp-upnext-active');
    }

    // 1. Auto-click the "Cancel" button if YouTube pops the Autoplay countdown
    document.querySelectorAll('button, [role="button"]').forEach(btn => {
      const text = (btn.innerText || btn.textContent || '').trim();
      if (text === 'Cancel') {
        btn.click();
        const card = btn.closest('ytm-autonav-endscreen-renderer, [class*="autonav" i], div');
        if (card && card !== document.body && card !== document.documentElement) {
          card.remove();
        }
      }
    });

    // 2. Remove all custom tags and autonav/endscreen elements
    document.querySelectorAll(
      'ytm-autonav-endscreen-renderer, ytm-autonav-bar, ytm-endscreen-renderer, ytm-endscreen-item-renderer, ytm-endscreen-element, ytm-autonav-endscreen-button-renderer, .ytp-upnext, .ytp-upnext-container, .ytp-autonav-endscreen-countdown-container, .ytp-cairo-refresh-autonav-overlay, .ytp-videowall-still, .ytp-endscreen-content, .html5-endscreen, .ytp-ce-element, [class*="videowall" i], [class*="ytp-endscreen" i], [class*="ytp-upnext" i], [class*="autonav-endscreen" i], [class*="ytm-endscreen" i], [class*="ytp-autonav" i], [class*="autonav" i], ytm-comments-entry-point-header-renderer, .ytm-comments-section, #comments, ytd-comments, ytm-engagement-panel-section-list-renderer'
    ).forEach(el => {
      if (el !== document.body && el !== document.documentElement) {
        el.remove();
      }
    });

    // 3. Scan text nodes specifically for "Up next in" to nuke any obfuscated wrapper card
    const walker = document.createTreeWalker(document.body || document.documentElement, NodeFilter.SHOW_TEXT);
    let node;
    while ((node = walker.nextNode())) {
      if (node.nodeValue && /Up next in/i.test(node.nodeValue)) {
        let parent = node.parentElement;
        while (parent && parent !== document.body && parent.parentElement !== document.body) {
          if (
            parent.tagName.toLowerCase().startsWith('ytm-') ||
            /autonav|endscreen|overlay/i.test(parent.className || '') ||
            parent.offsetHeight > 80
          ) {
            parent.remove();
            break;
          }
          parent = parent.parentElement;
        }
      }
    }

    // 4. Remove comment containers
    document.querySelectorAll('ytm-item-section-renderer, div').forEach(el => {
      if (/^Comments\s*\d+/i.test((el.innerText || '').trim())) el.remove();
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

  // Periodic heartbeat on watch pages to ensure dynamic end-screens never linger
  setInterval(() => {
    if (window.location.pathname.includes('/watch')) {
      killUpNextAndEndScreen();
    }
  }, 300);

  // End-of-video overlay interceptors
  document.addEventListener('timeupdate', (e) => {
    if (e.target && e.target.tagName === 'VIDEO') {
      const video = e.target;
      if (video.duration && (video.duration - video.currentTime < 20 || video.ended)) {
        killUpNextAndEndScreen();
      }
    }
  }, true);

  document.addEventListener('ended', killUpNextAndEndScreen, true);

  // SPA navigation hooks
  window.addEventListener('yt-navigate-finish', handleNavigation);
  window.addEventListener('ytm-navigate-finish', handleNavigation);
  window.addEventListener('popstate', handleNavigation);

  // MutationObserver for asynchronous dynamic rendering
  new MutationObserver(() => {
    const path = window.location.pathname;
    if (path === '/' || path === '') purgeHome();
    else if (path.includes('/results')) purgeShorts();
    else if (path.includes('/watch')) killUpNextAndEndScreen();
  }).observe(document.documentElement, { childList: true, subtree: true });

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', handleNavigation);
  } else {
    handleNavigation();
  }
})();
