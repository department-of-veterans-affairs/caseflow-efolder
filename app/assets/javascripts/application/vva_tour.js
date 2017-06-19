// Define the tour!
var tour = {
  id: "hello-hopscotch",
  steps: [
    {
      title: "Welcome to eFolder Express",
      content: "eFolder Express allows VA employees to bulk-download VBMS eFolders.",
      target: "page-title",
      placement: "right"
    },
    {
      title: "Retrieve documents",
      content: "Type in a Veteran ID number to find a veteran's eFolder.",
      target: "file_number",
      placement: "bottom"
    },
    {
      title: "Press search",
      content: "Click on the search button to retrieve the veteran's eFolder.",
      target: "submit-ee-search",
      placement: "left"
    }
  ],
  showPrevButton: true
};

// Start the tour!
window.VVATour = (function($){
  return {
    bind: function() {
      hopscotch.startTour(tour);
    }
  }
})($);
