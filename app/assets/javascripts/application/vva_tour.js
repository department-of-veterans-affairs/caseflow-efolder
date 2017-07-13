window.VVATour = (function($){
  return {
    bind: function() {
      var calloutMgr = hopscotch.getCalloutManager();
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
  }
})($);
