window.DownloadProgress = (function($) {
  var id, intervalID, openRequests = 0;

  // public
  return {
    currentTab: "progress",
    completed: false,

    initTabs: function() {
      var self = this;
      $(".cf-tab").click(function() {
        self.changeTabs($(this).attr("data-tab"));
      });
    },

    reload: function(changingTabs) {
      var self = this;

      if (id) {
        openRequests++
        $.get("/downloads/" + id + "/progress?current_tab=" + this.currentTab).then(function(fragment) {
          openRequests--;
          var scrollTop = $(".cf-tab-content")[0].scrollTop;
          $("#download-progress").html(fragment);

          if (!changingTabs) {
            $(".cf-tab-content")[0].scrollTop = scrollTop;
          }

          self.initTabs();
        }, function(){
          // error block. decrement openRequests so we send a new one.
          openRequests--;
        });
      }
    },

    changeTabs: function(tabName) {
      if(tabName != this.currentTab) {
        this.currentTab = tabName;
        this.reload(true);
      }
    },

    complete: function() {
      if(!this.completed) {
        this.changeTabs("completed");
        clearInterval(intervalID);
        this.completed = true;
      }
    },

    init: function(downloadId) {
      var self = this;
      id = downloadId;
      intervalID = window.setInterval(function() {
        // Only keep 2 requests open at a time, so they don't pile up
        // due to network slowness (e.g. on the VA VPN)
        if (openRequests <= 2) {
          self.reload(false);
        }
      }, 2000);

      $(document).ready(function() { self.initTabs(); });
    }
  };
})($);
