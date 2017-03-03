window.DownloadStatus = (function($) {
  var id, currentStatus, openRequests = 0;

  // public
  return {
    intervalID: null,
    recheck: function() {
      if (id) {
        openRequests++;
        $.getJSON("/downloads/" + id).then(function(download) {
          openRequests-- ;
          if (download.status != currentStatus) { location.reload(); }
        }, function(){
          // error block. decrement openRequests so we send a new one.
          openRequests--;
        });
      }
    },

    init: function(downloadId, downloadStatus) {
      var recheck = this.recheck;
      id = downloadId;
      currentStatus = downloadStatus;

      this.intervalID = window.setInterval(function() {
        // Only keep 2 requests open at a time, so they don't pile up
        // due to network slowness (e.g. VA VPN)
        if (openRequests <= 2) {
          recheck();
        }
      }, 1000);
    }
  };
})($);
