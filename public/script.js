$(document).ready(function() {
//  $('.domain > .click').click(function() {
//    $(this).siblings().slideToggle(500);
//  });
  var domains = $('.domain').each( function() {
    var domain = $(this);
    domain.children(":first").css("font-weight", "bolder");
    domain.children(":first").click( function() {
      //console.log('this: ');
      //console.log(this);
      var subdomains = domain.nextUntil(".domain");
      subdomains.each( function() {
        //console.log($(this).children(":first").text());
        //console.log($(this));
        //$(this).slideToggle(500);
        $(this).slideToggle(500);
        //console.log($(this));
      });
    });
  });
});
