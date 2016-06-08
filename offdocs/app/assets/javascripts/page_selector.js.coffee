ready = -> 
	$(document.activeElement).keyup (e) ->
		id = "#" + $(document.activeElement).attr('id').split("controls")[0]
		$(id).carousel(($(document.activeElement).val() - 1))

$(document).ready(ready)
$(document).on('page:load', ready)

