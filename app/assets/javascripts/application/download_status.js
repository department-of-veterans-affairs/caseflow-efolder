window.DownloadStatus = (function($) {
  var id, currentStatus;

  // public
  return {
    intervalID: null,
    recheck: function() {
      if (id) {
        $.getJSON("/downloads/" + id).then(function(download) {
          if (download.status != currentStatus) { location.reload(); }
        });
      }
    },

    init: function(downloadId, downloadStatus) {
      id = downloadId;
      currentStatus = downloadStatus;

      this.intervalID = window.setInterval(this.recheck, 1000);
    }
  };
})($);
