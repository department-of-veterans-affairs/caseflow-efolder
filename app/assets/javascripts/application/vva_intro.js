window.VVAIntro = (function($){
  return {
    bind: function() {
      var calloutMgr = hopscotch.getCalloutManager();
      calloutMgr.createCallout({
        id: 'vva-tour-1',
        target: 'vva-tour-1',
        placement: 'bottom',
        content: 'Downloads from eFolder Express now include Virtual VA documents.'
      });
    }
  }
})($);
