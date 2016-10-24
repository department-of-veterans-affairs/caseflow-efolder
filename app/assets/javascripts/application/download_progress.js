window.DownloadProgress = (function($) {
  var id, intervalID;

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
        console.log("currentTab" + this.currentTab);
        $.get("/downloads/" + id + "/progress?current_tab=" + this.currentTab).then(function(fragment) {
          var scrollTop = $(".cf-tab-content")[0].scrollTop;
          $("#download-progress").html(fragment);

          if(!changingTabs) {
            $(".cf-tab-content")[0].scrollTop = scrollTop;
          }

          self.initTabs();
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
        console.log("interval firing");
        self.reload(false);
      }, 2000);

      $(document).ready(function() { self.initTabs(); });
    }
  };
})($);
