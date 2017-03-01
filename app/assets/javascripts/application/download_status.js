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
          openRequests--;
        });
      }
    },

    init: function(downloadId, downloadStatus) {
      var recheck = this.recheck;
      id = downloadId;
      currentStatus = downloadStatus;

      this.intervalID = window.setInterval(function() {
        if (openRequests <= 2) {
          recheck();
        }
      }, 1000);
    }
  };
})($);
