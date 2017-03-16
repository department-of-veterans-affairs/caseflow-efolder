$(window).ready(function(){
 //Check to see if the window is top if not then display button
  $(window).scroll(function(){
   if ($(this).scrollTop() > 50) {
      $('.scroll-to-top').fadeIn(200);
   } else {
      $('.scroll-to-top').fadeOut(200);
    }
  });
  
  //Click event to scroll to top
  $('.scroll-to-top').click(function(){
    $('html, body').animate({scrollTop : 0},100);
   return false;
   });
 }); 