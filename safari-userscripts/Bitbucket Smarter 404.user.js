// ==UserScript==
// @name        Bitbucket Smarter 404
// @namespace   https://halfyak.org/safari-userscripts
// @author      Robbie Gates
// @description Adds a heuristic "maybe you meant" link to the bitbucket 404 page
// @match       https://bitbucket.org/*
// @inject-into content
// @grant       none
// ==/UserScript==

(() => {
  const errorDiv = document.getElementById("error");
  if (errorDiv) {
    const match = /\/(?<workspace>[^/]*)\/(?<repository>[^/]*).*/.exec(window.location.pathname);
    if (match) {
      const { workspace, repository } =  match.groups;
      const title = errorDiv.getElementsByTagName('h1')[0];
      const extra = document.createElement('p');
      extra.appendChild(document.createTextNode(
        `Check your safari profile, or if you got here from a script, perhaps you want to navigate to `));
      const link = document.createElement('a');
      link.setAttribute('href', `https://bitbucket.org/${workspace}/${repository}`);
      link.appendChild(document.createTextNode(`${workspace}/${repository}`));
      extra.appendChild(link);
      title.parentNode.insertBefore(extra, title.nextSibling);
    }
  }
  console.log('Bitbucket Smarter 404 is at your service');
})();
