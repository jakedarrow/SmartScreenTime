// SmartScreenTime: Hardcore Background Service Worker (Manifest V3)

const MAC_DAEMON_URL = 'http://127.0.0.1:48200';

chrome.runtime.onInstalled.addListener(async () => {
  const todayStr = new Date().toISOString().split('T')[0];
  await chrome.storage.local.set({
    todayStats: { date: todayStr, seconds: 0, minutes: 0 }
  });
  updateBadge(0);
});

// Listen for playback heartbeats
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'PLAYBACK_HEARTBEAT') {
    (async () => {
      const stats = await logPlaybackTime(message.seconds || 5, message.title, message.url);
      sendResponse({ success: true, todayMinutes: stats.minutes });
    })();
    return true;
  }
});

async function logPlaybackTime(seconds, title, url) {
  const todayStr = new Date().toISOString().split('T')[0];
  const { todayStats = { date: todayStr, seconds: 0, minutes: 0 } } = await chrome.storage.local.get('todayStats');
  
  let totalSeconds = todayStats.seconds || 0;
  if (todayStats.date !== todayStr) {
    totalSeconds = 0;
  }
  totalSeconds += seconds;
  const minutes = Math.floor(totalSeconds / 60);

  const updatedStats = { date: todayStr, seconds: totalSeconds, minutes };
  await chrome.storage.local.set({ todayStats: updatedStats });
  updateBadge(minutes);

  // Send to Mac Menu Bar App
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 1500);
    await fetch(`${MAC_DAEMON_URL}/api/watch-event`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ seconds, totalMinutesToday: minutes, title, url }),
      signal: controller.signal
    });
    clearTimeout(timeoutId);
  } catch (e) {
    // Mac daemon offline - ignore
  }

  return updatedStats;
}

function updateBadge(minutes) {
  chrome.action.setBadgeText({ text: minutes > 0 ? `${minutes}m` : '' });
  chrome.action.setBadgeBackgroundColor({ color: minutes >= 45 ? '#EF4444' : '#3B82F6' });
}
