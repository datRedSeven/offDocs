ready = ->
	$('.form-control.right-date').datepicker
  		language: 'ru'
  		autoclose: true
	$('.form-control.left-date').datepicker
  		language: 'ru'
  		autoclose: true




$(document).ready(ready)
$(document).on('page:load', ready)