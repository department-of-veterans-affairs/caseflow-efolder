window.StatsPanelToggle = (function($) {
  // private

  function switchActive(e) {
    var current = $(e.currentTarget).children('.ee-stat-option.active').first();
    var next = current.next()
    if (next.length === 0) { next = current.siblings().first(); }

    current.removeClass('active');
    next.addClass('active');
  }

  // public
  return {
    bind: function() {
      $('.ee-stat-panel.-toggle').on('click', switchActive);
    }
  };
})($);
