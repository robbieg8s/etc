// ==UserScript==
// @name        Atlassian Improvements
// @namespace   https://halfyak.org/safari-userscripts
// @author      Robbie Gates
// @description Tweaks the Atlassian Cloud UI
// @match       https://*.atlassian.net/*
// @match       https://bitbucket.org/*
// @inject-into content
// @grant       none
// ==/UserScript==

(() => {
  const akTopNav = 'AkTopNav';
  const removeUpgradeButton = () => {
    // Try to make this xpath pretty sensitive, since we run it every mutation
    const upgradeButtons = document.evaluate(
      './/nav/following-sibling::div/div[not(./@style="display: none;") and .//span[text()="Upgrade"]]',
      document.getElementById(akTopNav),
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
        Array.from(mutation.addedNodes)
          // Originally this was further filtered here, but team.atlassian.com behaved different
          // This might be a bit over eager, but check the behaviour on team.atlassian.com before fixing
          .forEach(addedNode => {
            // Hide the node (vs removal) so we don't break the bell
            addedNode.style.display = 'none';
            console.log('Atlassian Improvements hiding Notification ', addedNode);
          });
      });
  }))
    // Observe the whole document, as it gets rebuilt after load. Sometimes the element with id akTopNav, the
    // AtlasKit Top Navigation, is stable, but not always.
    .observe(document.getRootNode(), { childList: true, subtree: true });
  // Just in case we installed out mutation observed too late
  removeUpgradeButton();
  console.log('Atlassian Improvements is at your service');
})();
