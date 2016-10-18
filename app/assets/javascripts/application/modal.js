//= require jquery

/**
 * Accessible, reusable modal component.
 *
 * Requires certain class names to function properly:
 * - "cf-modal": the top level modal element
 * - "cf-modal-body": the modal body
 * - "cf-action-openmodal" Placed outside the modal. Triggers modal display.
 * - "cf-action-closemodal": Placed inside the modal. Closes the modal.
 * - "cf-modal-startfocus": the element that receives focus when the modal is opened.
 *      Also used to trap focus inside the modal for a11y.
 * - "cf-modal-endfocus": the last focusable element in the modal
 *
 * Accessibility:
 * - When the modal is closed, returns keyboard focus to the element
 *   that triggered the modal display
 * - Naively traps keyboard if the class "cf-modal-startfocus" is
 *   placed on the first focusable element and "cf-modal-endfocus"
 *   is placed on the last focusable element.
 *   TODO(alex): check out a more robust solution if this proves to
 *   be unwieldy, e.g. https://github.com/davidtheclark/focus-trap
 *
 */
window.Modal = (function($) {

  // Focus will be returned to this element
  // after the modal is closed. Important for a11y,
  // so keyboard users have a sensible flow.
  var returnEl;

  function openModal(e) {
    e.preventDefault();
    var target = $(e.target).attr("href");
    $(target).addClass("active");
    $('.cf-modal-startfocus').focus();
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
    var tabKey = (e.which === 9);

    if (escKey) {
      $('.cf-modal').trigger('click');
    }


    if (tabKey) {
      debugger;
      if ($('.cf-modal-endfocus').is(':focus')) {
        e.preventDefault();
        $('.cf-modal-startfocus').focus();
      }
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
