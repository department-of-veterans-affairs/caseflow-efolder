//= require jquery

window.Modal = (function($) {

  // set by openModal. focus will be returned to this element
  // after the modal is closed.
  // important for a11y, so keyboard users have a sensible flow.
  var returnEl;

  function openModal(e) {
    e.preventDefault();
    var target = $(e.target).attr("href");
    $(target).addClass("active");
    $('.cf-modal-title').focus();
    returnEl = e.target;
  }

  function closeModal(e) {
    e.stopPropagation();
    e.stopImmediatePropagation();

    if ($(e.target).hasClass("cf-modal") || $(e.target).hasClass("cf-action-closemodal")) {
      e.preventDefault();
      $(e.currentTarget).removeClass("active");
    }
    if (returnEl) {
      $(returnEl).focus();
    }
  }

  function onKeyDown(e) {
    var escKey = (e.which === 27);

    if (escKey) {
      $('.cf-modal').trigger('click');
    }
  }

  // public
  return {
    bind: function() {
      $('.cf-action-openmodal').on('click', openModal);
      $('.cf-modal').on('click', closeModal);
      $(window).on('keydown', onKeyDown);
    }
  };
})($);
