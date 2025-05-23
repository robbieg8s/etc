// ==UserScript==
// @name        Atlassian Improvements
// @namespace   https://halfyak.org/safari-userscripts
// @author      Robbie Gates
// @description Tweaks the Atlassian Cloud UI
// @match       https://*.atlassian.net/*
// @match       https://bitbucket.org/*
// @match       https://team.atlassian.com/*
// @inject-into content
// @grant       none
// ==/UserScript==

(() => {
  const removeUpgradeButton = () => {
    // Try to make this xpath pretty sensitive, since we run it every mutation
    const upgradeButtons = document.evaluate(
      './/nav[@aria-label="Actions"]//button[not(./@style="display: none;") and .//span[text()="Upgrade"]]',
      document.documentElement,
      null,
      XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE,
      null);
    for (let i = 0; i < upgradeButtons.snapshotLength; ++i) {
      const upgradeButton = upgradeButtons.snapshotItem(i);
      console.log('Atlassian Improvements hiding Upgrade ', upgradeButton);
      upgradeButton.style.display='none';
    }
  };

  (new MutationObserver((mutations, observer) => {
    // The upgrade button has moved around, so just always remove it
    removeUpgradeButton();
    mutations
      .filter(mutation => 'atlassian-navigation-notification-count' == mutation.target.getAttribute('id'))
      .forEach(mutation => {
        // This needs to be tested on team.atlassian.com.
        Array.from(mutation.addedNodes)
          .forEach(addedNode => {
            // Hide the node (vs removal) so we don't break the bell
            addedNode.style.display = 'none';
            console.log('Atlassian Improvements hiding Notification ', addedNode);
          });
      });
  }))
    // Observe the whole document, as it gets rebuilt after load. Recent confluence navigation update have remove
    // AtlasKit id elements which were previously useful for wayfinding.
    .observe(document.getRootNode(), { childList: true, subtree: true });
  // Just in case we installed our mutation observer too late
  removeUpgradeButton();
  console.log('Atlassian Improvements is at your service');
})();
