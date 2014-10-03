if (Meteor.isClient) {
  
  $('a[href^="#"]').on('click',function (e) {
	     e.preventDefault();
        $(this).fadeOut(1000);
        $("body, html").animate({ 
            scrollTop: $( $(this).attr('href') ).offset().top 
        }, 900);
	});
  



  if (Meteor.isServer) {
    Meteor.startup(function () {
      // code to run on server at startup
    });
  }
}
