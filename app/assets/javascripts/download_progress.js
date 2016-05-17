window.DownloadProgress = (function($) {
  var id, intervalID;

  // public
  return {
    reload: function() {
      if (id) {
        $.get("/downloads/" + id + "/progress").then(function(fragment) {
          $("#download-progress").html(fragment);
        });
      }
    },

    complete: function() {
      clearInterval(intervalID);
    },

    init: function(downloadId) {
      id = downloadId;
      intervalID = window.setInterval(this.reload, 1000);
    }
  };
})($);