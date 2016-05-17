window.DownloadStatus = (function($) {
  var id, currentStatus;

  // public
  return {
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

      window.setInterval(this.recheck, 1000);
    }
  };
})($);