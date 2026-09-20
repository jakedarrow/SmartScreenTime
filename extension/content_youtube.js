// Search-Only YouTube: Distraction-Free YouTube Engine (Desktop & Mobile)
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
