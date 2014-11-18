$ = global.jQuery = require('jquery')
require('bootstrap')

$('a[href^="#"]').on 'click', (e) ->
  e.preventDefault()

  $(this).fadeOut(1000)

  $("body, html").animate({
    scrollTop: $($(this).attr('href')).offset().top
  }, 900)
