window.VVALink = (function($){
  var calloutMgr = hopscotch.getCalloutManager();
  var vvaLink = document.getElementById('cf-view-coachmarks-link');

  function removeCallouts(e) {
    calloutMgr.removeAllCallouts();
  }

  function verifyElementExists(coachmarkID) {
    return document.getElementById(coachmarkID);
  }

  return {
    bind: function() {
      $('#cf-view-coachmarks-link').on('click', removeCallouts)

      if (verifyElementExists('vva-tour-1')) {
        calloutMgr.createCallout({
          id: 'vva-tour-1',
          target: 'vva-tour-1',
          placement: 'bottom',
          content: 'Downloads from eFolder Express now include Virtual VA documents.'
        });
      }
      // The confirming downloads page has 2 coachmarks, hence they're in the same conditional
      else if (verifyElementExists('vva-tour-2')){
        calloutMgr.createCallout({
          id: "vva-tour-2",
          content: "The total number of documents that will be retrieved from each database is listed here.",
          target: "vva-tour-2",
          placement: "top"
        });
        calloutMgr.createCallout({
          id: "vva-tour-3",
          content: "The Source column shows the name of the database from which the file will be retrieved.",
          target: "vva-tour-3",
          placement: "left"
        });
      }
      else if (verifyElementExists('vva-tour-4')){
        calloutMgr.createCallout({
          id: 'vva-tour-4',
          target: 'vva-tour-4',
          placement: 'bottom',
          xOffset: "center",
          content: 'The total number of documents that will be downloaded from each database is listed here.'
        });
      }
    }
  }
})($);
