ready = ->
	$('.partial-buttons').html("<%= escape_javascript (render partial: 'buttons', locals: {user: current_user, doc: @doc}) %>")
	
$(document).ready(ready)
$(document).on('page:load', ready)


