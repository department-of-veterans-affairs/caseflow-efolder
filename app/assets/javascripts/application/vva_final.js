window.VVAFinal = (function($){
  return {
    bind: function() {
      var calloutMgr = hopscotch.getCalloutManager();
      calloutMgr.createCallout({
        id: 'vva-tour-4',
        target: 'vva-tour-4',
        placement: 'bottom',
        xOffset: "center",
        content: 'The total number of documents that will be downloaded from each database is listed here.'
      });
    }
  }
})($);
