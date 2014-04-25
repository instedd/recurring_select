window.RecurringTimepickerDialog =
  class RecurringTimepickerDialog
    constructor: (@timepicker_selector) ->
      @initDialogBox()
      @setTime(@timepicker_selector.data('initial-value'))
      @updateElements()
      setTimeout @positionDialog, 10 # allow initial render

    initDialogBox: ->
      $(".rs_holder").remove()

      open_in = $("body")
      open_in = $(".ui-page-active") if $(".ui-page-active").length
      open_in.append @template()
      @outer_holder = $(".rs_holder")
      @inner_holder = @outer_holder.find ".rs_dialog"
      @content = @outer_holder.find ".rs_dialog_content"
      @positionDialog(true)
      @mainEventInit()
      @content.find('.rs_hour').focus()
      @outer_holder.trigger "recurring_select:dialog_opened"

    positionDialog: (initial_positioning) =>
      @positionDialogNearControl(initial_positioning)

    positionDialogNearControl: =>
      @outer_holder.css {
        width: $(document).width(),
        height: $(document).height()
      }

      offset = @timepicker_selector.offset()

      new_style_hash =
        "position": "absolute"
        "top" : (offset.top + @timepicker_selector.height() + 10) + "px"
        "left" : offset.left + "px"

      @inner_holder.css new_style_hash

    close: =>
      $(window).off 'keyup', @closeHandler
      @outer_holder.remove()

    save: =>
      @timepicker_selector.recurring_timepicker('save', @getTime())
      @close()

# ========================= Init Methods ===============================

    mainEventInit: ->
      dialog = @
      hourInput = @content.find '.rs_hour'
      minuteInput = @content.find '.rs_minute'

      @closeHandler = (e) ->
        dialog.close() if e.which == 27

      # Tap hooks are for jQueryMobile
      @outer_holder.on 'click tap', @save
      @content.on 'click tap', (e) ->
        e.stopPropagation()
      @content.on 'click tap', 'a', (e) ->
        dialog[$(this).data('action')]()
        e.preventDefault()
      $(window).on 'keyup', @closeHandler
      @content.on 'change', '.rs_hour, .rs_minute', ->
        dialog.setTime(hourInput.val() + ':' + minuteInput.val())
        dialog.updateElements()
      hourInput.on 'keydown', (e) ->
        dialog.incrementHour() if e.keyCode == 38
        dialog.decrementHour() if e.keyCode == 40
      minuteInput.on 'keydown', (e) ->
        dialog.incrementMinute(1) if e.keyCode == 38
        dialog.decrementMinute(1) if e.keyCode == 40


    getTime: =>
      "#{@hourStr()}:#{@minuteStr()}"

    setTime: (time) =>
      timeArray = time.split(':');
      @hour = parseInt(timeArray[0])
      @minute = parseInt(timeArray[1])

      @hour = 0 if isNaN(@hour)
      @minute = 0 if isNaN(@minute)

      @hour = Math.min(Math.max(@hour, 0), 23)
      @minute = Math.min(Math.max(@minute, 0), 59)

    incrementHour: =>
      @changeHour(1)
      @updateElements()

    decrementHour: =>
      @changeHour(-1)
      @updateElements()

    changeHour: (delta) =>
      @hour += delta
      @hour = (@hour + 24) % 24

    incrementMinute: (delta) =>
      delta ||= 15
      @changeMinute(delta - @minute % delta)
      @updateElements()

    decrementMinute: (delta) =>
      delta ||= 15
      if @minute % delta == 0
        @changeMinute(-delta)
      else
        @changeMinute(-@minute % delta)
      @updateElements()

    changeMinute: (delta) =>
      @minute += delta
      @changeHour(-1) if @minute < 0
      @changeHour(+1) if @minute >= 60
      @minute = (@minute + 60) % 60

    updateElements: =>
      $('.rs_hour', @content).val(@hourStr())
      $('.rs_minute', @content).val(@minuteStr())

    hourStr: =>
      "#{@hour}"

    minuteStr: =>
      (if @minute < 10 then '0' else '') + @minute

    template: () ->
      str = "
      <div class='rs_holder rs_timepicker rs_collapsible_holder'>
        <div class='rs_dialog'>
          <div class='rs_dialog_content'>

            <table>
              <tr>
                <td>
                  <a href='#' data-action='incrementHour'>
                    <i class='rs-icon-up'></i>
                  </a>
                </td>
                <td class='separator'>&nbsp;</td>
                <td>
                  <a href='#' data-action='incrementMinute'>
                    <i class='rs-icon-up'></i>
                  </a>
                </td>
              </tr>
              <tr>
                <td><input type='text' class='rs_hour' maxlength='2'></td>
                <td class='separator'>:</td>
                <td><input type='text' class='rs_minute' maxlength='2'></td>
              </tr>
              <tr>
                <td>
                  <a href='#' data-action='decrementHour'>
                    <i class='rs-icon-down'></i>
                  </a>
                </td>
                <td class='separator'></td>
                <td>
                  <a href='#' data-action='decrementMinute'>
                    <i class='rs-icon-down'></i>
                  </a>
                </td>
              </tr>
            </table>
          </div>
        </div>
      </div>
      "
