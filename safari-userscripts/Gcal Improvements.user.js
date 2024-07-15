// ==UserScript==
// @name        Gcal Improvements
// @namespace   https://halfyak.org/safari-userscripts
// @author      Robbie Gates
// @description Tweaks the Google Calendar UI
// @match       https://calendar.google.com/calendar/*
// @inject-into content
// @grant       none
// @run-at      document-idle
// ==/UserScript==

(() => {
  // Get rid of the screen space consuming mini calendar - i never use this.
  document.getElementById('drawerMiniMonthNavigator').style.display='none';
  console.log('Gcal Improvements is at your service');
})();
