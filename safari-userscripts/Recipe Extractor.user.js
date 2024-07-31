// ==UserScript==
// @name        Recipe Extractor
// @namespace   https://halfyak.org/safari-userscripts
// @author      Robbie Gates
// @description Sniff Recipe objects in JSON+LD from webpages
// @match       https://*/*
// @inject-into content
// @grant       none
// @run-at      document-idle
// ==/UserScript==

(() => {
  const isSchemaOrgRecipe = (item) =>
    item['@context'] && ('schema.org' == new URL(item['@context']).hostname) && ('Recipe' == item['@type']);
  var ldJsons = document.evaluate(
    './/script[@type="application/ld+json"]', document.getRootNode(), null, XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null);
  var recipes = Array.from({length:ldJsons.snapshotLength}).flatMap((_,i) => {
    var item = JSON.parse(ldJsons.snapshotItem(i).text);
    if (Array.isArray(item)) {
      return item.flatMap(subitem => isSchemaOrgRecipe(subitem) ? [ subitem ] : []);
    } else if (isSchemaOrgRecipe(item)) {
      return [ item ] ;
    } else if (('https://schema.org' == item['@context']) && Array.isArray(item['@graph'])) {
      return item['@graph'].flatMap(subitem => ('Recipe' == subitem['@type']) ? [ subitem ] : []);
    } else {
      return [];
    }
  });
  if (recipes.length > 0) {
    const div = document.createElement('div');
    // Z index here is a guess - i'm just upping it as required for now
    div.style = 'position: fixed; top: 0px; right: 0px; z-index:100000;';
    div.append(document.createTextNode(`Recipe Extractor found ${recipes.length} recipes`));
    const ul = document.createElement('ul');
    recipes.forEach(recipe => {
      const a = document.createElement('a');
      const name = recipe.name?.trim() || 'unnamed';
      a.append(document.createTextNode(name));
      a.title = `Copy JSON+LD for ${name} to clipboard`;
      a.href = '#';
      a.onclick = async () => {
        await navigator.clipboard.writeText(JSON.stringify(recipe));
        return false;
      };
      const li = document.createElement('li');
      li.append(a);
      ul.append(li);
    });
    div.append(ul);
    document.body.append(div);
    console.log(div);
    console.log(recipes);
  }
  console.log(`Recipe Extractor is at your service (${recipes.length} / ${ldJsons.snapshotLength})`);
})();
