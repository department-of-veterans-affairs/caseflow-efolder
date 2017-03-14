$(window).ready(function(){
 
 //Check to see if the window is top if not then display button
  $(window).scroll(function(){
   if ($(this).scrollTop() > 50) {
      $('.scrollToTop').fadeIn(200);
   } else {
      $('.scrollToTop').fadeOut(200);
    }
  });
  
  //Click event to scroll to top
  $('.scrollToTop').click(function(){
    $('html, body').animate({scrollTop : 0},100);
   return false;
  });
  
});