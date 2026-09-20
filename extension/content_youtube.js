// Search-Only YouTube: Distraction-Free YouTube Engine (Desktop & Mobile)
(function () {
  'use strict';

  function init() {
    handleNavigation();
    setupPurgeObserver();
    setupVideoEndObserver();
    setupPlaybackTelemetry();

    // YouTube SPA navigation listeners (Desktop & Mobile)
    window.addEventListener('yt-navigate-finish', handleNavigation);
    window.addEventListener('ytm-navigate-finish', handleNavigation);
    window.addEventListener('popstate', handleNavigation);
  }

  function handleNavigation() {
    const path = window.location.pathname;
    const isHome = path === '/' || path === '';

    // 1. Mobile & Desktop Home View State
    if (isHome) {
      document.body.classList.add('sst-mobile-home', 'sst-home-view');
      document.documentElement.classList.add('sst-mobile-home');
      purgeMobileHomeFeed();
      focusNativeSearchBar();
    } else {
      document.body.classList.remove('sst-mobile-home', 'sst-home-view');
      document.documentElement.classList.remove('sst-mobile-home');
    }

    // 2. Hard block direct /shorts/ navigation
    if (path.startsWith('/shorts/')) {
      const videoId = path.split('/shorts/')[1]?.split('?')[0];
      if (videoId) {
        window.location.replace(`https://www.youtube.com/watch?v=${videoId}`);
      } else {
        window.location.replace('https://www.youtube.com/');
      }
      return;
    }

    // 3. Search Results: Aggressively purge shorts
    if (path.includes('/results')) {
      purgeShortsFromDOM();
    }

    // 4. Watch Page: Disable autoplay countdown, end-screen suggestions, and comments
    if (path.includes('/watch')) {
      disableAutoplay();
      purgeEndScreenOverlays();
      purgeComments();
    }
  }

  function purgeMobileHomeFeed() {
    if (window.location.pathname !== '/' && window.location.pathname !== '') return;

    // Purge chips filter row (All, Gaming, Podcasts...)
    const chips = document.querySelectorAll('ytm-feed-filter-chip-bar-renderer, ytm-chip-cloud-renderer, .feed-filter-chip-bar-renderer');
    chips.forEach(el => el.remove());

    // Purge browse feed container & video items on home
    const feedElements = document.querySelectorAll(
      'ytm-single-column-browse-results-renderer, ytm-browse ytm-section-list-renderer, [tab-identifier="FEwhat_to_watch"], ytm-pivot-bar-renderer'
    );
    feedElements.forEach(el => el.remove());
  }

  function purgeComments() {
    // 1. Tag & Class Based
    const comments = document.querySelectorAll(
      'ytm-comments-entry-point-header-renderer, ytm-comments-header-renderer, ytm-comment-section-renderer, ytm-comment-thread-renderer, .ytm-comments-section, ytd-comments, #comments, [class*="comments-entry-point"], [class*="comment-entry-point"], [section-identifier*="comment"], ytm-engagement-panel-section-list-renderer[target-id="engagement-panel-comments-section"]'
    );
    comments.forEach(el => {
      const card = el.closest('ytm-item-section-renderer') || el;
      card.remove();
    });

    // 2. Text & Structural Pattern Matching for mobile Comments container
    const candidates = document.querySelectorAll('ytm-item-section-renderer, [class*="comment"], div');
    candidates.forEach(el => {
      if (el.children.length > 0 && el.children.length < 8) {
        const text = (el.innerText || '').trim();
        if (/^Comments\s*\d+/i.test(text)) {
          el.remove();
        }
      }
    });
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
    }, 150);
  }

  // Actively remove Shorts elements & any search item containing /shorts/
  function purgeShortsFromDOM() {
    const shortsLinks = document.querySelectorAll('a[href*="/shorts/"]');
    shortsLinks.forEach((link) => {
      const card = link.closest(
        'ytd-video-renderer, ytd-grid-video-renderer, ytd-reel-shelf-renderer, ytd-rich-shelf-renderer, ytd-item-section-renderer, grid-shelf-view-model, ytm-video-with-context-renderer, ytm-media-item'
      );
      if (card) {
        card.remove();
      }
    });

    const reelShelves = document.querySelectorAll(
      'ytd-reel-shelf-renderer, ytd-rich-shelf-renderer[is-shorts], grid-shelf-view-model, ytm-reel-shelf-renderer, ytm-reel-item-renderer'
    );
    reelShelves.forEach((shelf) => shelf.remove());
  }

  // Actively remove end-screen suggestions and videowall tiles
  function purgeEndScreenOverlays() {
    const player = document.querySelector('.html5-video-player');
    if (player && player.classList.contains('ytp-show-tiles')) {
      player.classList.remove('ytp-show-tiles');
    }

    const endScreens = document.querySelectorAll(
      '.ytp-videowall-still, .ytp-endscreen-content, .ytp-ce-element, .html5-endscreen, .ytm-endscreen-renderer, [class*="videowall"], .ytp-suggestion-set'
    );
    endScreens.forEach(el => {
      el.remove();
    });
  }

  function setupVideoEndObserver() {
    document.addEventListener('timeupdate', (e) => {
      if (e.target && e.target.tagName === 'VIDEO') {
        const video = e.target;
        if (video.duration && (video.duration - video.currentTime < 15 || video.ended)) {
          purgeEndScreenOverlays();
        }
      }
    }, true);

    document.addEventListener('ended', () => {
      purgeEndScreenOverlays();
    }, true);
  }

  function setupPurgeObserver() {
    const observer = new MutationObserver(() => {
      const path = window.location.pathname;
      if (path === '/' || path === '') {
        purgeMobileHomeFeed();
      } else if (path.includes('/results')) {
        purgeShortsFromDOM();
      }
      if (path.includes('/watch')) {
        purgeEndScreenOverlays();
        purgeComments();
      }
    });

    observer.observe(document.documentElement, {
      childList: true,
      subtree: true
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

  function setupPlaybackTelemetry() {
    setInterval(() => {
      if (!window.location.pathname.includes('/watch')) return;
      const video = document.querySelector('video');
      if (video && !video.paused && !video.ended && document.visibilityState === 'visible') {
        chrome.runtime?.sendMessage?.({
          type: 'PLAYBACK_HEARTBEAT',
          url: window.location.href,
          title: document.title,
          seconds: 5
        });
      }
    }, 5000);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
