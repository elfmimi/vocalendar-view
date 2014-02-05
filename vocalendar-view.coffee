$ = jQuery

start_of_week = 1
day_names = [ '日', '月', '火', '水', '木', '金', '土' ]
default_status_text = '　+VOCALENDAR'
theme_colors = [
    { color: "#0F4B38", bgcolor: "#41A587" }, # VOCALENDER メイン
    { color: "#AB8B00", bgcolor: "#E0C240" }, # VOCALENDAR 放送系
]
day_unit = 86400000

# 動的にとろうとするとうまくいかないので定数にしてある
nav1_height = 24
footer1_height = 20
record_height = 17

today = (new Date(Date.now()))
show_year = today.getFullYear()
show_month = today.getMonth()

start_of_month =
end_of_month =
start_c =
sat_c =
sun_c =
this_month_end_date =
prev_month_end_date =
num_row =
num_row_records =
today_rc =
ajax_request =
sorted_events =
    undefined

parentContainer =
eventDetailPopup = 
moreEventsPopup =
    undefined

nav1 =
monthOfView =
viewContainer1 =
statusLine =
footer1 =
loading1 =
mvEventContainer2 =
    undefined

activate_link = (s) ->
    s.replace /(?:(https?):\/\/[A-Za-z0-9-_\.]+(?::[0-9]+)?|pic.twitter.com)(\/[A-Za-z0-9-_=&%\/\.]*)?(\?[A-Za-z0-9-_=&%\/\.]+)?(#[A-Za-z0-9-_=&%\/\.]*)?/g , (match,proto) ->
        url =
            if proto # == "http" or proto == "https"
                match
            else
                "http://" + match
        "<a target=_BLANK href=\"#{url}\">#{match}</a>"
remove_link = (s) ->
    s.replace /[ ]*http:\/\/[A-Za-z0-9-_\.]+(:[0-9]+)?(\/[A-Za-z0-9-_=&%\/\.\?]*)?[ ]*/g , ''

rect_of_object = (o) ->
    { left: o.offset().left, top: o.offset().top, width: o.width(), height: o.height() }

calc_param = () ->
    start_of_month = new Date(show_year, show_month, 1)
    end_of_month = new Date(show_year, show_month + 1, 0)
    start_c = (start_of_month.getDay() + 7 - start_of_week) % 7
    sat_c = 6 - start_of_week
    sun_c = (7 - start_of_week) % 7
    this_month_end_date = end_of_month.getDate()
    prev_month_end_date = (new Date(show_year, show_month, 0)).getDate()
    num_row = (~~( (start_c + this_month_end_date - 1) / 7)) + 1
    num_row_records = ((((($(window).height() - nav1_height - footer1_height) / num_row) | 0) / record_height) | 0) - 1
    today_rc =
        if today.getFullYear() == show_year and today.getMonth() == show_month
            today.getDate() - 1 + start_c
        else
            -1
    sorted_events = []
    eventDetailPopup =
    moreEventsPopup =
        undefined

createView = (parent) ->

    parentContainer = parent

    container = $('<div id=container class=locale-ja style="width: 100%; position: relative; height: 100%;">')
        .appendTo parentContainer

    calendarContainer = $('<div class=calendar-container>')
        .appendTo container

    # ここの hideDetail と hideMore は前方参照している
    $(window).keydown (ev) ->
        if ev.keyCode == 27 # ESC
            hideDetail() or hideMore()
    calendarContainer.click ->
        hideDetail() or hideMore()

    nav1 = $('<div id=nav1 class=header style="overflow: hidden">')
        .appendTo calendarContainer
    dateControls = $('<div class=date-controls>')
        .appendTo nav1
    navTable = $('<table class=nav-table cellspacing=0 cellpadding=0 border=0>')
        .appendTo dateControls
    $('<tbody>')
        .appendTo( navTable )
        .append $('<tr>').append( $('<td class=date-nav-buttons>')
            .append( today_btn = $('<button id=todayButton1 class=today-button style="margin: 2px">').append "今月" )
            .append( back_btn = $('<img id=navBack1 class="navbutton navBack" width=22 height=17 src=blank.gif title="前" tabindex=0 role=button>') )
            .append( forward_btn = $('<img id=navForward1 class="navbutton navForward" width=22 height=17 src=blank.gif title="次" tabindex=0 role=button>') ) )
    $('> tbody > tr',  navTable)
        .append( $('<td>')
            .append( monthOfView = $('<div id=monthOfView>').text "" ) )
    
    calendarContainer1 = $('<div id=calendarContainer1 class=view-container-border style="height: 100%">')
        .appendTo calendarContainer
    viewContainer1 = $('<div id=viewContainer1 class=view-container style="height: 560px">')
        .appendTo calendarContainer1

    footer1 = $('<table id=footer1 class=footer width=100% cellspacing=0 cellpadding=0>')
        .appendTo( calendarContainer1 )
        .append $('<tbody>') \
        .append $('<tr>') \
        .append $('<td valign=bottom>') \
        .append (statusLine = $('<div style="text-align: right;">').text(default_status_text))

    loading1 = $('<div id=loading1 class=loading style="right: 25px; display: none;">')
        .appendTo( calendarContainer1 )
        .append '読み込み中...'

    mvContainer = $('<div class=mv-container>')
        .appendTo viewContainer1
    mvDaynamesTable = $('<table id=mvDaynamesTable class=mv-daynames-table cellspacing=0 cellpadding=0>')
        .appendTo mvContainer
    mvEventContainer2 = $('<div id=mvEventContainer2 class=mv-event-container>')
        .appendTo mvContainer

    do->
        mvDaynamesTable.append $('<tbody>').append tr = $('<tr>')
        for c in [0..7-1]
            $('<th class=mv-dayname>')
                .text( day_names[(c+start_of_week)%7] )
                .appendTo tr
        undefined

    # refill_calendar() については前方参照している
    today_btn.click () ->
        today = (new Date(Date.now()))
        show_year = today.getFullYear()
        show_month = today.getMonth()
        refill_calendar()    

    back_btn.click () ->
        show_month -= 1
        if show_month < 0
            show_month = 11
            show_year -= 1
        refill_calendar()    

    forward_btn.click () ->
        show_month += 1
        if show_month >= 12
            show_month = 0
            show_year += 1
        refill_calendar()    

monthRows =
monthRowBackgrounds =
monthBackgrounds =
    undefined

fill_month_background = () ->
    monthRows =
    monthRowBackgrounds =
    monthBackgrounds =
        undefined

    mvEventContainer2.empty()

    monthRows =
        for i in [1..num_row]
            top = (i-1)*100.0/num_row
            height = 100.0/num_row
            style = if i < num_row then "top: #{top}%; height: #{height}%" else "top: #{top}%; bottom: 0"
            $("<div class=month-row style=\"#{style}\">")
                .appendTo mvEventContainer2

    monthRowBackgrounds =
        for row in monthRows
            $('<table class=st-bg-table cellspacing=0 cellpadding=0>')
                .appendTo row
            
    monthBackgrounds =
        for row_bg, r in monthRowBackgrounds
            tbody = $('<tbody>')
                .appendTo row_bg
            tr = $('<tr>')
                .appendTo tbody
            for c in [0..7-1]
                rc = r*7+c
                day_n = rc - start_c + 1
                nonmonth = day_n <= 0 or day_n > this_month_end_date
                class_names = "st-bg"
                class_names += " st-bg-fc" if c == 0
                class_names += " st-bg-today" if rc == today_rc
                class_names += " st-bg-next" if rc == today_rc + 1
                class_names += " st-bg-nonmonth" if nonmonth
                $("<td class=\"#{class_names}\">").append( '&nbsp;' )
                    .appendTo tr

monthRowGrids =
monthDayTitles =
monthRowRecords =
    undefined

fill_month_rows = () ->
    monthRowGrids =
        for row in monthRows
            $('<table class=st-grid cellspacing=0 cellpadding=0>').append( '<tbody>' )
                .appendTo row
    
    monthDayTitles =
        for row_grid, r in monthRowGrids
            tbody = $('> tbody', row_grid)
            tr = $('<tr>')
                .appendTo tbody
            for c in [0..7-1]
                rc = r*7+c
                day_n = rc - start_c + 1
                nonmonth = day_n <= 0 or day_n > this_month_end_date
                class_names = "st-dtitle"
                class_names += " st-dtitle-fr" if r == 0
                class_names += " st-dtitle-fc" if c == 0
                class_names += " st-dtitle-today" if rc == today_rc
                class_names += " st-dtitle-next" if rc == today_rc + 1
                class_names += " st-dtitle-down" if rc == today_rc + 7
                class_names += " st-dtitle-nonmonth" if nonmonth
                class_names += " st-dtitle-sat" if c == sat_c
                class_names += " st-dtitle-sun" if c == sun_c
                date =
                    if day_n <= 0
                        "#{prev_month_end_date + day_n}"
                    else if day_n == 1
                        "#{show_month+1}月 1日"
                    else if day_n <= this_month_end_date
                        "#{day_n}"
                    else if day_n == this_month_end_date + 1
                        "#{(show_month + 1) % 12 + 1}月 1日"
                    else
                        "#{day_n - this_month_end_date}"
                $("<td class=\"#{class_names}\">").append( $('<span class=ca-cdp>').append date )
                    .appendTo tr

    monthRowRecords =
        for row_grid, r in monthRowGrids
            tbody = $('> tbody', row_grid)
            for rr in [0...num_row_records] by 1
                tr = $('<tr>')
                    .appendTo tbody

time_of_date = (date) ->
    hour = date.getHours()
    minute = date.getMinutes()
    hour = (if hour < 10 then '0' else '') + hour
    minute = (if minute < 10 then '0' else '') + minute
    "#{hour}:#{minute}"
date_of_date = (date) ->
    "#{date.getMonth() + 1}月 #{date.getDate()} 日 (#{day_names[date.getDay()]}曜日)"
date_time_of_date = (date) ->
    "#{date_of_date(date)} #{time_of_date(date)}"
year_date_of_date = (date) ->
    "#{date.getFullYear()}年 #{date_of_date(date)}"
year_date_time_of_date = (date) ->
    "#{year_date_of_date(date)} #{time_of_date(date)}"

text_of_timespan = (allday, start_value, end_value) ->
    start_date = new Date(start_value)
    end_date = new Date(end_value)
    if allday and start_value + day_unit == end_value
        if start_date.getFullYear() == show_year
            date_of_date(start_date)
        else
            year_date_of_date(start_date)
    else if allday
        end_date = new Date(end_value - day_unit)
        if start_date.getFullYear() == show_year and end_date.getFullYear() == show_year
            "#{date_of_date(start_date)} ～ #{date_of_date(end_date)}"
        else
            "#{year_date_of_date(start_date)} ～ #{year_date_of_date(end_date)}"
    else if start_value == end_value
        if start_date.getFullYear()  == show_year
            "#{date_time_of_date(start_date)} ～"
        else
            "#{year_date_time_of_date(start_date)} ～"
    else if ((start_value + day_unit*9/24) / day_unit | 0) == ((end_value + day_unit*9/24) / day_unit | 0)
        if start_date.getFullYear()  == show_year
            "#{date_time_of_date(start_date)} ～ #{time_of_date(end_date)}"
        else
            "#{year_date_time_of_date(start_date)} ～ #{time_of_date(end_date)}"
    else if ((start_value + day_unit*9/24) / day_unit | 0) + 1 == ((end_value + day_unit*9/24) / day_unit | 0)
        if start_date.getFullYear() == show_year
            "#{date_time_of_date(start_date)} ～ 翌 #{time_of_date(end_date)}"
        else
            "#{year_date_time_of_date(start_date)} ～ 翌 #{time_of_date(end_date)}"
    else if start_date.getFullYear() == show_year and end_date.getFullYear() == show_year
        date_time_of_date(start_date) + " ～ " +
            date_time_of_date(end_date)
    else
        year_date_time_of_date(start_date) + " ～ " +
            year_date_time_of_date(end_date)

positionDetail = (rect) ->
    popup = eventDetailPopup
    parent = popup.parent()
    window_left = $(window).scrollLeft()
    window_top = $(window).scrollTop()
    window_width = $(window).width()
    window_height = $(window).height()
    width = popup.width()
    height = popup.height()
    margin_v = 8
    margin_h = 8
    spacing_v = 4
    pos_x = rect.pageX

    if pos_x - width / 2 >= window_left + margin_h and
    pos_x + width / 2 <= window_left + window_width - margin_h
        left = pos_x - width / 2
    else if pos_x - width / 2 < window_left + margin_h
        left = window_left + margin_h
    else
        left = window_left + window_width - margin_h - width

    if height <= rect.top - window_top - spacing_v
        top = rect.top - spacing_v - height
    else if rect.top + rect.height + spacing_v + height <= window_top + window_height
        top = rect.top + rect.height + spacing_v
    else if height + margin_v * 2 <= window_height
        top = window_top + window_height - height - margin_v
    else if height <= window_height
        top = window_top + window_height - height
    else
        top = window_top + margin_v
        detail_content = $('.detail-content', popup)
        detail_content.css('height', window_height - margin_v * 2 - (height - detail_content.height())).css('overflow-y', 'scroll')
    # eventDetailPopup は .bubble で position:absolute になっているが
    # どこが基準になるか的確に知る方法はある？
    left -= parentContainer.offset().left
    top -= parent.offset().top
    popup.css('left', left).css('top', top) # .css('width', width)
    popup.css( 'display', 'none' ).css( 'visibility', 'visible' ).fadeIn( 'fast' )

showDetail = (event, rect_with_pos) ->
    click = (ev) ->
        ev.stopPropagation()
    if eventDetailPopup
        do (eventDetailPopup) ->
            eventDetailPopup.fadeOut( -> eventDetailPopup.remove() )
        if eventDetailPopup.data().event == event
            eventDetailPopup = undefined
            return
    max_width = $(window).width() - 120
    width = 660
    width = max_width if width > max_width
    eventDetailPopup = $('<div class=bubble style="z-index: 3001; left: 0px; top: 0px;">')
        .css( 'width', width )
        .appendTo( viewContainer1 )
        .css( 'visibility', 'hidden' )
        .data( { event: event } )
        .click( click )
        .append $('<table class=bubble-table cellspacing=0 cellpadding=0>') \
        .append $('<tbody>') \
        .append( $('<tr>')
            .append( $('<td class=bubble-cell-side>')
                .append $('<div id="tl:1" class=bubble-corner>') \
                .append $('<div class="bubble-sprite bubble-tl">') )
            .append( $('<td class=bubble-cell-main>')
                .append $('<div class=bubble-top>') )
            .append( $('<td class=bubble-cell-side>')
                .append $('<div id="tr:1" class=bubble-corner>') \
                .append '<div class="bubble-sprite bubble-tr">' ) ) \
        .append( $('<tr>')
            .append $('<td class=bubble-mid colspan=3>') \
            .append $('<div id="bubbleContent:1" style="overflow: hidden">') \
            .append (details = $('<div class=details>')) ) \
        .append( $('<tr>')
            .append( $('<td>')
                .append $('<div id="bl:1" class=bubble-corner>') \
                .append $('<div class="bubble-sprite bubble-bl">') )
            .append( $('<td>')
                .append $('<div class=bubble-bottom>') )
            .append( $('<td>')
                .append $('<div id="br:1" class=bubble-corner>') \
                .append $('<div class="bubble-sprite bubble-br">') ) )

    eventDetailPopup
        .append $('<div id="bubbleClose:1" class=bubble-closebutton>') \
        .click -> hideDetail('fast')

    details
        .append $('<span class=title>').css('color', event.theme.color) \
        .append "詳細 #{event.summary}"
    details
        .append (detailContent = $('<div class=detail-content>'))

    date = text_of_timespan(event.allday, event.start_date_value, event.end_date_value)
        
    detailContent
        .append $('<div class=detail-item>') \
        .append( $('<span class=event-details-label>').append "日時" ) \
        .append( $('<span class=event-when>').append date )
    where = event.where or ""
    if where
        if where.match(/^https?:\/\/[A-Za-z0-9-_\.]+(:[0-9]+)?(\/[A-Za-z0-9-_=&%\/\.\?]*)?$/)
            label = "リンク"
            map_link = ""
        else
            label = "場所"
            map_link = " (<a target=_BLANK href=\"http://maps.google.com/maps?hl=ja&q=#{encodeURI(remove_link(where))}\">地図</a>)"

        detailContent
            .append $('<div class=detail-item>') \
            .append( $('<span class=event-details-label>').append label ) \
            .append( $('<span class=event-where>').append (activate_link(where) + map_link))

    if event.description
        detailContent
            .append $('<div class=detail-item>') \
            .append( $('<span class=event-details-label>').append "説明" ) \
            .append( $('<span class=event-description>').append activate_link(event.description) )

    details
        .append $('<div class=separator>').css('background-color', event.theme.color)

    links = $('<div class=links>')
        .appendTo details

    if event.url
        event_url_escaped = encodeURIComponent(event.url)
        tweet_text_escaped = encodeURIComponent("ボカロ関連イベントの共有カレンダー【 VOCALENDAR | ボカレンダー 】#{event.summary}")

        links
            .append( $("<a target=_BLANK href=\"#{event.url}\">").append "詳細»")
            .append( "&nbsp;&nbsp;" )
            .append( $('<div style="display: inline; vertical-align: middle; font-size: 20px">') )
#            .append( $("<iframe allowtransparency=true frameborder=0 scrolling=no src=\"https://platform.twitter.com/widgets/tweet_button.html#count=none&dnt=true&hashtags=vocalendar&id=twitter-widget-2&lang=ja&size=m&text=#{tweet_text_escaped}&url=#{event_url_escaped}\" style=\"width:70px; height:20px;\">") ) 
            .append( "&nbsp;&nbsp;" )
            .append( "マイ カレンダーにコピー»" )
    else
        links
            .append( "詳細»" )
            .append( "&nbsp;&nbsp;" )
#            .append( "twitterで共有»" )
            .append( "&nbsp;&nbsp;" )
            .append( "マイ カレンダーにコピー»" )

    positionDetail(rect_with_pos)

hideDetail = (speed) ->
    if eventDetailPopup
        do (eventDetailPopup) ->
            eventDetailPopup.fadeOut speed, ->
                eventDetailPopup.remove()
        eventDetailPopup = undefined
        return true

insertSpacer = (record, r, c) ->
    record
        .append $('<td class=st-c>')

insertEvent = (record, event, options) ->
    summary = event?.summary
    { time, colspan, continuation } = options
    click = (ev) ->
        ev.stopPropagation()
        target = $(ev.target)
        rect = rect_of_object( $(ev.target) )
        rect.pageX = ev.pageX
        rect.pageY = ev.pageY
        showDetail(event, rect)
    enter = ->
        statusLine.text(event.summary)
    leave = ->
        statusLine.text(default_status_text)
    if time
        record
            .append $('<td class=st-c>').click( click ).hover( enter, leave ).attr('title', event.summary) \
            .append $('<div class=st-c-pos>') \
            .append $("<div class=\"ca-evp te\" style=\"color: #{event.theme.color}\">") \
            .append( $('<span class=te-t>').append "#{event.start_time}" ) \
            .append( $('<span class=te-s>').append "#{summary}" )
    else
        start_time = event.start_time if not continuation
        colspan = (" colspan=#{colspan}" if colspan) or ""
        st_ad = [] or [$("<div class=st-ad-ml style=\"border-color: transparent #{event.theme.bgcolor}\">")]
        st_ad_mpad = " " or " st-ad-mpad " or " st-ad-mpadr " or " st-ad-mpad st-ad-mpadr "
        record        
            .append $("<td class=st-c#{colspan}>") \
            .append $("<div class=st-c-pos>").click( click ).hover( enter, leave ).attr('title', event.summary) \
            .append $("<div class=\"ca-evp#{st_ad_mpad}rb-n\" style=\"background-color: #{event.theme.bgcolor}\">") \
            .append $('<div class=rb-ni>').append(st_ad) \
            .append (if start_time then "(#{start_time})" else "") + "#{summary}"
    return

positionMore = () ->
    base = viewContainer1
    base_pos = base.offset()
    base_width = base.width()
    window_top = $(window).scrollTop()
    window_left = $(window).scrollLeft()
    window_width = $(window).width()
    window_height = $(window).height()
    margin_h = 4
    margin_v = footer1_height
    width = moreEventsPopup.width()
    height = moreEventsPopup.height()
    rc = moreEventsPopup.data()
    node_pos = monthDayTitles[rc.row][rc.col].offset()
    left = node_pos.left - base_pos.left
    top = node_pos.top - base_pos.top
    top -= 3
    top = window_top + window_height - base_pos.top - margin_v - height if top + height > window_top + window_height - base_pos.top - margin_v
    left = window_left + margin_h - base_pos.left if node_pos.left - margin_h < window_left
    left = window_left + window_width - margin_h - width - base_pos.left if node_pos.left + width + margin_h > window_left + window_width
    moreEventsPopup.css('left', left).css('top', top)

showMore = (r, c) ->
    events = sorted_events
    hideMore()
    hideDetail()
    date = new Date(show_year, show_month, 1 - start_c + 7 * r + c)
    title_text = year_date_of_date(date)
    day_start = date.valueOf()
    day_end = day_start + day_unit
    class_names = "cc-titlebar"
    class_names += " cc-titlebar-sat" if c == sat_c
    class_names += " cc-titlebar-sun" if c == sun_c
    moreEventsPopup = $('<div class=cc style="z-index: 1001; left: 0px; top: 0px; width: 225px; visibility: visible; position: absolute">')
        .appendTo( viewContainer1 )
        .data( { row: r; col: c } )
        .css( 'display', 'none' )
        .append(ccTitlebar = $("<div class=\"#{class_names}\">")
                .append(ccClose = $('<div class=cc-close>'))
                .append($('<div class=cc-title>').text title_text))
        .append $('<div class=cc-body>') \
        .append $('<div class=st-contents>') \
        .append $('<table class=st-grid cellspacing=0 cellpadding=0>') \
        .append (tbody = $('<tbody>'))

    ccTitlebar.click (ev) ->
        ev.stopPropagation()
        hideDetail() or hideMore()
    ccClose.click (ev) ->
        ev.stopPropagation()
        hideMore('fast')
    moreEventsPopup.click (ev) ->
        ev.stopPropagation()
        hideDetail()

    pointer = 0
    while pointer < events.length
        event = events[pointer]
        do (event) ->
            click = (ev) ->
                ev.stopPropagation()
                rect = rect_of_object( $(ev.target) )
                rect.pageX = ev.pageX
                rect.pageY = ev.pageY
                showDetail(event, rect )
            enter = ->
                statusLine.text(event.summary)
            leave = ->
                statusLine.text(default_status_text)
            if event.start_date_value >= day_end
            else if event.gd$originalEvent # gd$recurrence
                # recurrence からインストタンス化されたイベント？ 必ず存在するわけではないのがよく分からない。
            else if event.end_date_value > day_start # and event.start_date_value < day_end
                if event.allday || event.end_date_value - event.start_date_value >= day_unit
                    continuation = event.start_date_value < day_start
                    start_time = event.start_time if not continuation
                    tbody
                        .append $('<tr>') \
                        .append $('<td class=st-c>') \
                        .append $('<div class=st-c-pos>').click( click ).hover( enter, leave ).attr('title', event.summary) \
                        .append $("<div class=\"ca-evp rb-n\" style=\"background-color: #{event.theme.bgcolor}\">") \
                        .append (if start_time then "(#{start_time})" else "") + event.summary
                else if event.start_date_value >= day_start
                    tbody
                        .append $('<tr>') \
                        .append $('<td class=st-c>') \
                        .append $('<div class=st-c-pos>').click( click ).hover( enter, leave ).attr('title', event.summary) \
                        .append $("<div class=\"ca-evp rb-n\" style=\"color: #{event.theme.color}\">") \
                        .append( $('<span class=te-t>').append event.start_time ) \
                        .append( $('<span class=te-s>').append event.summary )
        pointer += 1

    positionMore()
    moreEventsPopup.css( 'display', 'none' ).fadeIn( 'fast' )

hideMore = (speed) ->
    if moreEventsPopup
        do (moreEventsPopup) ->
            moreEventsPopup.fadeOut speed, ->
                moreEventsPopup.remove()
        moreEventsPopup = undefined
        return true

insertMore = (record, count, r, c) ->
    click_background = (ev) ->
        ev.stopPropagation()
        hideDetail() or hideMore() or showMore(r, c)
    click_daytitle = (ev) ->
        ev.stopPropagation()
        hideDetail() or showMore(r, c)
    click = (ev) ->
        ev.stopPropagation()
        showMore(r, c)
    monthDayTitles[r][c].unbind().click click_daytitle
    monthBackgrounds[r][c].unbind().click click_background
    record
        .append $('<td class="st-c st-more-c">') \
        .click( click_background ) \
        .append $('<span class="ca-mlp st-more st-moreul">') \
        .append( if num_row_records == 1 then "#{count} 件" else "他 #{count} 件" ) \ 
        .click( click )
    

event_colspan = (event, day_start, c) ->
    colspan =
        if event.allday
            ~~((event.end_date_value - day_start + day_unit - 1 )/day_unit)
        else if event.end_date_value - event.start_date_value >= day_unit
            ~~((event.end_date_value - day_start + day_unit - 1)/day_unit)
        else
            ~~((event.end_date_value - day_start + day_unit * 12 / 24 - 1)/day_unit)
    colspan = 1 if colspan == 0
    colspan = 7 - c if colspan + c > 7
    colspan

fill_week = (records, events, first_date, r) ->
    pointer = 0

    grid =
        for c in [0...7]
            for rr in [0...num_row_records] by 1
                false

    more =
        for c in [0...7]
            0

    memo =
        for c in [0...7]
            undefined

    day_end = first_date.valueOf()
    for c in [0...7]
        day_start = day_end
        day_end += day_unit

        count = 0
        while pointer < events.length
            event = events[pointer]
            if event.start_date_value >= day_end
                break
            if event.gd$originalEvent # gd$recurrence
                # recurrence からインストタンス化されたイベント？ 必ず存在するわけではないのがよく分からない。
            else if event.end_date_value > day_start and ( event.start_date_value >= day_start or event.end_date_value - event.start_date_value >= day_unit )
                while count < num_row_records - 1 and grid[c][count] != false
                    count += 1
                if count < num_row_records - 1
                    grid[c][count] = event
                else if count == num_row_records - 1 && more[c] == 0
                    memo[c] = event
                if count >= num_row_records - 1
                    colspan = event_colspan(event, day_start, c)
                    for cc in [c...c+colspan] by 1
                        more[cc] += 1
                count += 1
            pointer += 1

        if count > num_row_records
            memo[c] = undefined

        for rr in [0...num_row_records-1] by 1
            if true
                event = grid[c][rr]
                if event == true
                    # すでに埋まっている
                else if event == false
                    insertSpacer(records[rr], rr, c)
                else
                    colspan = event_colspan(event, day_start, c)
                    continuation = event.start_date_value < day_start
                    if colspan > 1
                        grid[c]
                        colspan = 7 - c if colspan + c > 7
                        for cc in [c...c+colspan] by 1
                            grid[cc][rr] = true
                        insertEvent( records[rr], event, { colspan, continuation })
                    else
                        if event.allday || continuation # event.end_date_value - event.start_date_value >= day_unit # 
                            insertEvent( records[rr], event, { continuation })
                        else # if event.start_date_value >= day_start
                            insertEvent( records[rr], event, { time: event.start_time })

    rr = num_row_records - 1
    day_end = first_date.valueOf()
    for c in [0...7]
        day_start = day_end
        day_end += day_unit

        if event = memo[c]
            colspan = event_colspan(event, day_start, c)
            # colspan = ~~((event.end_date_value - day_start)/day_unit)
            # colspan = 7 - c if colspan + c > 7
            check = true
            for cc in [c...c+colspan] by 1
                if more[cc] != 1
                    check = false
                    break
            if check
                for cc in [c...c+colspan] by 1
                    more[cc] = 0
                if event.allday
                    insertEvent( records[rr], event, { colspan } )
                else
                    insertEvent( records[rr], event, { time: event.start_time } )
            else
                insertMore( records[rr], more[c], r, c )
        else if more[c] == 0
            insertSpacer(records[rr], r, c)
        else
            insertMore( records[rr], more[c], r, c )
            

# Closure Compiler に通すためjsonのプロパティーへのアクセスは文字列で行う事
composeEvent = (core, theme) ->
    event = { core, theme }
    event.allday = core['allday']
    if event.allday
        event.start_date_value = Date.parse(core['start_date']) - day_unit*9/24
        event.end_date_value = Date.parse(core['end_date']) - day_unit*9/24
    else
        event.start_date_value = Date.parse(core['start_datetime'])
        event.end_date_value = Date.parse(core['end_datetime'])
    if not event.allday
        event.start_time = do () ->
            time = new Date(event.start_date_value)
            hour = time.getHours()
            minute = time.getMinutes()
            hour = (if hour < 10 then '0' else '') + hour
            minute = (if minute < 10 then '0' else '') + minute
            "#{hour}:#{minute}"
    if core['tags'] and core['tags']['length'] > 0
        tag_names = for tag in core['tags']
            tag['name']
        tag_text = "【#{tag_names.join("/")}】"
        event.summary = tag_text + core['summary']
    else
        event.summary = core['summary']
    event.description = core['description']
    event.where = core['location']
    event.url = "http://vocalendar.jp/core/events/#{core['id']}"
    return event

json_loaded = (json, cal) ->
    events = json
    sorted_events = do ->
        events_overridden = {}
        events_with_recurrence = []
        for event in events
            events_with_recurrence.push composeEvent(event, theme_colors[0])
        sorted_events.concat(events_with_recurrence).sort (a,b) ->
            return -1 if a.start_date_value < b.start_date_value
            return +1 if a.start_date_value > b.start_date_value
            return -1 if a.allday and not b.allday
            return +1 if not a.allday and b.allday
            return -1 if a.end_date_value > b.end_date_value
            return +1 if a.end_date_value < b.end_date_value
            return -1 if a.summary < b.summary
            return +1 if a.summary > b.summary
            return 0

    return

do_fill = ->
    for records in monthRowRecords
        for record in records
            record.empty()
    for r in [0...num_row] by 1
        first_date = new Date(show_year, show_month, 1 - start_c + 7 * r) 
        fill_week( monthRowRecords[r], sorted_events, first_date, r)
    return

str_of_date = (date, sep = '-') ->
    year = date.getFullYear()
    month = date.getMonth() + 1
    mday = date.getDate()
    month = (if month < 10 then '0' else '') + month
    mday = (if mday < 10 then '0' else '') + mday
    return "#{year}#{sep}#{month}#{sep}#{mday}"

reload = ->
    start_min = str_of_date(new Date(show_year, show_month, 1 - start_c), '/')
    start_max = str_of_date(new Date(show_year, show_month, 1 - start_c + 7 * num_row), '/')
    loading1.css('display', 'inline')
    core_query_url = (page) ->
        'http://vocalendar.jp/core/events.json?callback=?&startTime='+start_min+'T00:00:00&endTime='+start_max+'T00:00:00&page='+(page+1)
#        "core-2014-02-page#{page+1}.json"
    loaded = (json, page) ->
        json_loaded(json, page)
        do_fill()
        all_loaded = json.length == 0
        if all_loaded
            ajax_request = undefined
            loading1.css('display', 'none')
        else
            page = page + 1
            ajax_request.push $.getJSON(core_query_url(page), (json)->loaded(json,page))
    if ajax_request
        for request in ajax_request
            request.abort()
    ajax_request = []
    ajax_request.push $.getJSON(core_query_url(0), (json)->loaded(json,0))

refill_calendar = () ->
    eventDetailPopup.remove() if eventDetailPopup
    moreEventsPopup.remove() if moreEventsPopup
    calc_param()
    monthOfView.text "#{show_year}年 #{show_month+1}月"
    fill_month_background()
    fill_month_rows()
    reload()

resize_window = () ->
    nav1_height = nav1.height()
    footer1_height = footer1.height()
    viewContainer1.css('height', (parentContainer.height() - nav1_height - footer1_height))
    num_row_records = (((((parentContainer.height() - nav1_height - footer1_height) / num_row) | 0) / record_height) | 0) - 1
    num_row_records = 1 if num_row_records == 0
    monthRowRecords =
        for row_grid, r in monthRowGrids
            tbody = $('> tbody', row_grid)
            $('> tr', tbody).slice(1).remove()
            for rr in [0...num_row_records] by 1
                tr = $('<tr>')
                    .appendTo tbody
    do_fill()
    positionMore() if moreEventsPopup

$.fn['vocalendarView'] = () ->
    createView($(@))
    refill_calendar()
    resize_window()
    $(window).resize () ->
        resize_window()
