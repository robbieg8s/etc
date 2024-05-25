// ==UserScript==
// @name        Atlassian Improvements
// @namespace   https://halfyak.org/safari-userscripts
// @author      Robbie Gates
// @description Tweaks the Atlassian Cloud UI
// @match       https://*.atlassian.net/*
// @inject-into content
// @grant       none
// ==/UserScript==

(() => {
  const akTopNav = 'AkTopNav';
  const removeUpgradeButton = () => {
    const upgradeButtons = document.evaluate(
      './/nav/following-sibling::div/div[.//span[text()="Upgrade"]]',
      document.getElementById(akTopNav),
      null,
      XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE,
      null);
    for (let i = 0; i < upgradeButtons.snapshotLength; ++i) {
      const upgradeButton = upgradeButtons.snapshotItem(i);
      if (upgradeButton.style.display != 'none') {
        console.log('Atlassian Improvements removing upgradeButton:');
        console.log(upgradeButton);
        upgradeButton.style.display='none';
      }
    }
  };

  (new MutationObserver((mutations, observer) => {
    // Like most user scripts, this is probably a bit brittle, but if it starts to miss things due to deeper trees,
    // i suspect it can be patched up using loops rather than querying specific node path attributes
    if (0 != mutations
      .filter(mutation => mutation.type == "childList")
      .map(mutation => mutation.target?.parentNode?.parentNode)
      .filter(node => node?.getAttribute && (akTopNav == node.getAttribute('id')))
      .length) {
      removeUpgradeButton();
    }
    mutations
      .filter(mutation => 'atlassian-navigation-notification-count' == mutation.target.getAttribute('id'))
      .forEach(mutation => {
        Array.from(mutation.addedNodes)
          // Originally this was further filtered here, but team.atlassian.com behaved different
          // This might be a bit over eager, but check the behaviour on team.atlassian.com before fixing
          .forEach(addedNode => {
            // Hide the node (vs removal) so we don't break the bell
            addedNode.style.display = 'none';
            console.log('Atlassian Notification Snooze hiding', addedNode);
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
