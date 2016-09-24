# A new window/tab event can be one of the following
# ctrlKey (Windows)
# metaKey (OSX)
# shiftKey (OS agnositc)
# New tab with middle click
is_new_window_or_tab_event = (event) ->
  middle_click_event = (event.button && event.button == 1)
  event.ctrlKey || event.metaKey || event.shiftKey || middle_click_event

restore = ->
  $('.loading-indicator').hide()

  $('body').removeClass('no-scroll')
  # re-enable mobile scrolling event
  $('body').unbind('touchmove')

ready = ->
  $('.js-navigation').on('click', (event) ->
    return if is_new_window_or_tab_event(event)
    $('.loading-indicator').show()

    $('body').addClass('no-scroll')
    # disable mobile scrolling event
    $('body').on('touchmove', (e) -> e.preventDefault())
  )


$(document).ready(ready)
$(document).on('page:restore', restore)
