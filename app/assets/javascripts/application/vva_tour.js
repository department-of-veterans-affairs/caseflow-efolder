// Define the tour!
var tour = {
  id: "vva-tour",
  steps: [
    {
      title: "Welcome to eFolder Express",
      content: "eFolder Express allows VA employees to bulk-download VBMS eFolders.",
      target: "page-title",
      placement: "right"
    },
    {
      content: "Type in a Veteran ID number to find a veteran's eFolder.",
      target: "file_number",
      placement: "bottom"
    },
    {
      title: "Press search",
      content: "Click on the search button to retrieve the veteran's eFolder.",
      target: "submit-ee-search",
      placement: "left",
      multipage: true
    },
    {
      content: "The total documents found from the veteran's eFolder and the Legacy Content Manager can be found here. The source of each document is listed in the table below.",
      target: "retrieve_documents",
      placement: "bottom",
      xOffset: "center",
      multipage: true,
      showPrevButton: false
    },
    {
      content: "The total documents retrieved are listed in the completed tab. Document errors during the retrieval process are displayed in the errors tab along with their source.",
      target: "vva_notice",
      placement: "bottom",
      showPrevButton: false
    },
    {
      content: "Once all the files are successfully retrieved, click the 'Download' eFolder button at the top or bottom of the page to download the complete eFolder.",
      target: "download_efolder_button",
      placement: "right",
      showPrevButton: false
    }
  ]
};

//TODO(marian): fix why the 5th coachmark doesn't show up after the files have been retrieved

// Start the tour!
window.VVATour = (function($){
  return {
    bind: function() {
      hopscotch.startTour(tour);
    }
  }
})($);
