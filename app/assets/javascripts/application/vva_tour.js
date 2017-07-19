window.VVATour = (function($){
  var calloutMgr = hopscotch.getCalloutManager();

  var vvaCallout1 = {
    id: 'vva-tour-1',
    target: 'vva-tour-1',
    placement: 'bottom',
    content: 'Downloads from eFolder Express now include Virtual VA documents.'
  };

  var vvaCallout2 = {
    id: 'vva-tour-2',
    content: 'The total number of documents that will be retrieved from each database is listed here.',
    target: 'vva-tour-2',
    placement: 'top'
  };

  var vvaCallout3 = {
    id: 'vva-tour-3',
    content: 'The Source column shows the name of the database from which the file will be retrieved.',
    target: 'vva-tour-3',
    placement: 'left'
  };

  var vvaCallout4 = {
    id: 'vva-tour-4',
    target: 'vva-tour-4',
    placement: 'bottom',
    xOffset: 'center',
    content: 'The total number of documents that will be downloaded from each database is listed here.'
  };

  function getToggleCalloutsFn(calloutIds) {
    var callouts = Array.prototype.slice.call(arguments);
    return function() {
      for (var calloutIndex in callouts){
        if (calloutMgr.getCallout(callouts[calloutIndex].id)) {
          calloutMgr.removeCallout(callouts[calloutIndex].id);
          $('#cf-view-coachmarks-link').text('Show tutorial');
        }
        else {
          calloutMgr.createCallout(callouts[calloutIndex]);
          $('#cf-view-coachmarks-link').text('Hide tutorial');
        }
      }
    }
  }

  return {
    bind: function() {
      var calloutArgs;
      function verifyElementExists(coachmarkID) {
        return document.getElementById(coachmarkID);
      }
      if (verifyElementExists('vva-tour-1')) {
        calloutMgr.createCallout(vvaCallout1);
        calloutArgs = getToggleCalloutsFn(vvaCallout1);
      }
      // The confirming downloads page has 2 coachmarks, hence they're in the same conditional
      else if (verifyElementExists('vva-tour-2')){
        calloutMgr.createCallout(vvaCallout2);
        calloutMgr.createCallout(vvaCallout3);
        calloutArgs = getToggleCalloutsFn(vvaCallout2, vvaCallout3);
      }
      else if (verifyElementExists('vva-tour-4')){
        calloutMgr.createCallout(vvaCallout4);
        calloutArgs = getToggleCalloutsFn(vvaCallout4);
      }

      $('#cf-view-coachmarks-link').on('click', calloutArgs)
    }
  }
})($);
