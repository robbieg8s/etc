// ==UserScript==
// @name        Gmail Improvements
// @namespace   https://halfyak.org/safari-userscripts
// @author      Robbie Gates
// @description Installs extra gmail shortcuts
// @match       https://mail.google.com/mail/*
// @inject-into content
// @grant       none
// ==/UserScript==

(() => {
  const openViewHeuristically = () => {
    const makeMatchers = (domain, ...linkTexts) => linkTexts.map(linkText => ({
      domain,
      // XPath 1.0 lacks ends-with or regex matchers that would permit a precise url check here.
      // So do an approximate check with contains, and refine below. Note that if -before or -after
      // do not find the marker they return empty, so this will fail false for no match.
      xpath: `.//a[contains(substring-before(substring-after(./@href, "https://"), "/"), "${domain}") and normalize-space(string(.))="${linkText}"]`
    }));
    const found = [
      // Bitbucket has a bit of an array of link texts in use
      ...makeMatchers('bitbucket.org', 'View this pull request', 'View commit', 'View this commit', 'View all commits'),
      ...makeMatchers('atlassian.net', 'View page', 'View blog post')
    ].some(({ domain, xpath }) => {
      const xpathResults = document.evaluate(xpath, document);
      let node = null;
      while (node = xpathResults.iterateNext()) {
        const href = node.href;
        const hostname = (new URL(href)).hostname;
        if ((hostname === domain) || hostname.endsWith(`.${domain}`)) {
          window.open(href, '_blank');
          return true;
        }
      }
      return false;
    });
    if (!found) {
      alert('No view action available for this email sorry');
    }
  };

  const initalState = () => ({
    // timestamp of last g keydown, or null if no usable g.
    gKeyDown: null,
    // Seen u keydown within the time limit since the prior g
    pendingGU: false,
    // Seen l keydown
    pendingL: false
  });
  // State for tracking keyboard interactions
  var state = initalState();

  const keyCodeIs = (letter, eventData) =>
    (letter.charCodeAt(0) === eventData.keyCode);

  const hasModifiers = keyDown => (
    keyDown.altKey || keyDown.ctrlKey || keyDown.metaKey || keyDown.repeat || keyDown.shiftKey
  );
  // https://developer.mozilla.org/en-US/docs/Web/API/Element/keydown_event
  window.addEventListener('keydown', keyDown => {
    if (hasModifiers(keyDown)) {
      // Any key with modifiers, so reset state
      state = initalState();
    } else if (keyCodeIs('G', keyDown)) {
      state.gKeyDown = keyDown.timeStamp;
    } else if (keyCodeIs('U', keyDown) && state.gKeyDown && (keyDown.timeStamp < state.gKeyDown + 1000)) {
      state.pendingGU = true;
    } else if (keyCodeIs('L', keyDown)) {
      state.pendingL = true;
    } else {
      // Anything else, assume we're out of sync and reset state
      state = initalState();
    }
  });
  // https://developer.mozilla.org/en-US/docs/Web/API/Element/keyup_event
  window.addEventListener('keyup', keyUp => {
    if (!keyCodeIs('G', keyUp)) {
      if (keyCodeIs('U', keyUp) && state.pendingGU) {
        // Redirect to the unread page of gmail
        document.location = 'https://mail.google.com/mail/u/0/#search/is%3Aunread'
      } else if (keyCodeIs('L', keyUp) && state.pendingL) {
        // Use heuristics to open the right page for the email
        openViewHeuristically();
      }
      // In any case, clear pending states to ignore cases like interleaved key events
      state = initalState();
    } // else no need to react to G up, but don't clear state
  });

  // https://developer.mozilla.org/en-US/docs/Web/API/Element/input_event
  window.addEventListener('input', () => {
    // For any input element input, reset state so we don't track random typing etc.
    state = initalState();
  });
  console.log('Gmail Improvements is at your service');
})();
