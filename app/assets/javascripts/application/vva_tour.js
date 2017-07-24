window.VVATour = (function($) {
  var calloutManager = hopscotch.getCalloutManager();

  function initCallouts(callouts, onAllClosed) {
    var countClosed = 0;

    callouts.forEach(function(callout) {
      callout.onClose = function() {
        countClosed++;
        if (countClosed === callouts.length) {
          onAllClosed();
        }
      };
      calloutManager.createCallout(callout);
    });
  }

  function execOnPageReady(fn) {
    if (document.readyState === 'complete') {
      fn();
      return;
    }
    window.addEventListener('load', fn);
  }

  function setCurrentPageCallouts(showCallouts, callouts) {
    execOnPageReady(function() {
      var showCalloutsWithSession = JSON.parse(window.localStorage.getItem('showCallouts')) || showCallouts;
      var SHOW_TUTORIAL_TEXT = "See what's new!";
      var HIDE_TUTORIAL_TEXT = 'Hide tutorial';

      var hideTutorialText = showCalloutsWithSession ? HIDE_TUTORIAL_TEXT : SHOW_TUTORIAL_TEXT;
      var $hideTutorialLink = $('<a href="#" id="cf-view-coachmarks-link">' + hideTutorialText + '</a>');
      $('#hide-tutorial-parent').prepend($hideTutorialLink)

      var allCalloutsClosed = !showCalloutsWithSession;

      function onAllCalloutsClosed() {
        $hideTutorialLink.text(SHOW_TUTORIAL_TEXT);
        allCalloutsClosed = true;
      }

      function createCallouts() {
        allCalloutsClosed = false;
        initCallouts(callouts, onAllCalloutsClosed);
      }

      $('#cf-view-coachmarks-link').click(function() {
        if (allCalloutsClosed) {
          window.localStorage.showCallouts = true;
          $hideTutorialLink.text(HIDE_TUTORIAL_TEXT);
          createCallouts();
        } else {
          window.localStorage.showCallouts = false;
          $hideTutorialLink.text(SHOW_TUTORIAL_TEXT);
          calloutManager.removeAllCallouts();
          onAllCalloutsClosed();
        }
      });

      if (showCalloutsWithSession) {
        createCallouts();
      }
    });
  }

  function initNewPage(showCallouts) {
    setCurrentPageCallouts(showCallouts, [{
      id: 'vva-tour-1',
      target: 'vva-tour-1',
      placement: 'bottom',
      content: 'Downloads from eFolder Express now include Virtual VA documents.'
    }]);
  }

  function initConfirmPage(showCallouts) {
    setCurrentPageCallouts(showCallouts, [
      {
        id: 'vva-tour-2',
        content: 'The total number of documents that will be retrieved from each database is listed here.',
        target: 'vva-tour-2',
        placement: 'top'
      },
      {
        id: 'vva-tour-3',
        content: 'The Source column shows the name of the database from which the file will be retrieved.',
        target: 'vva-tour-3',
        placement: 'left'
      }
    ]);
  }

  // This app will load the progress partial multiple times and insert it into the page via jQuery.
  // We only want to do this initialization once, however.
  var progressPageInitialized = false;
  function initProgressPage(showCallouts) {
    if (progressPageInitialized) {
      return;
    } 
    progressPageInitialized = true;

    if (showCallouts) {
      $.post('/increment_vva_coachmarks_status');
    }

    setCurrentPageCallouts(showCallouts, [{
      id: 'vva-tour-4',
      target: 'vva-tour-4',
      placement: 'bottom',
      xOffset: 'center',
      content: 'The total number of documents that will be downloaded from each database is listed here.'
    }]);
  }

  return {
    initNewPage: initNewPage,
    initConfirmPage: initConfirmPage,
    initProgressPage: initProgressPage
  };
})($);
