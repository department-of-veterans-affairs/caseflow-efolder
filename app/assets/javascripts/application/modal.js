//= require jquery

/**
 * Accessible, reusable modal component.
 *
 * Certain classnames are used here for functionality:
 * - "cf-modal": the top level modal element
 * - "cf-action-openmodal" Placed outside the modal. Triggers modal display.
 * - "cf-action-closemodal": Placed inside the modal. Closes the modal.
 * - "cf-modal-startfocus": the element that receives focus when the modal is opened.
 *      Also used to trap focus inside the modal for a11y.
 * - "cf-modal-endfocus": the last focusable element in the modal
 *   NOTE: accessibility features won't work if "cf-modal-startfocus"
 *   and "cf-modal-endfocus" are not used.
 *
 * See _confirm_download_anyway_modal.html.erb for an example of the HTML.
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
 *
 */
window.Modal = (function($) {
  // Focus will be returned to this element
  // after the modal is closed. Important for a11y,
  // so keyboard users have a sensible flow.
  var $lastFocused;
  // The currently active modal element, used to
  // scope later actions.
  var $activeModal;


  function openModal(e) {
    var target = $(e.target).attr("href");
    $activeModal = $(target);
    $activeModal.addClass("active");
    $lastFocused = document.activeElement;
    $activeModal.find('.cf-modal-startfocus').focus();
  }

  function closeModal(e) {
    e.stopPropagation();
    e.stopImmediatePropagation();

    if ($(e.target).hasClass("cf-modal") || $(e.target).hasClass("cf-action-closemodal")) {
      e.preventDefault();
      $(e.currentTarget).removeClass("active");
    }

    // Return focus to the element that had focus before the modal was opened.
    if ($lastFocused) {
      $lastFocused.focus();
    }
  }

  function onKeyDown(e) {
    var escKey = (e.which === 27);
    var tabKey = (e.which === 9);
    var tabShift = (e.shiftKey && e.keyCode == 9);

    if (escKey) {
      $('.cf-modal').trigger('click');
    }

    if (tabKey) {
      if ($activeModal.find('.cf-modal-endfocus').is(':focus')) {
        // Prevent the user from tabbing out of the modal,
        // and instead return focus to the top of the modal.
        e.preventDefault();
        $activeModal.find('.cf-modal-startfocus').focus();
      }
    }
    if (tabShift) {
      if ($activeModal.find('.cf-modal-startfocus').is(':focus')) {
        // Prevent the user fom tabbing backwards out of the modal.
        e.preventDefault();
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
