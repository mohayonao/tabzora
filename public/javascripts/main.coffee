"use strict"

jQuery ->
    NOP = ()->

    # ugly-patch (SEE ALSO: http://mohayonao.hatenablog.com/entry/2012/04/29/080015)
    if /mac.*firefox/i.test(navigator.userAgent)
        setInterval NOP, 500

    [$query, $info] = [$("#query"), $("#info")]
    readInterval = 0
    isPlaying = false
    timer = new Worker("/javascripts/muteki-timer.js")

    withkeypress = false
    $query.on "keypress", -> withkeypress = true
    $query.on "keyup", (e)->
        query = this.value.trim()
        read query if query.length and withkeypress and e.keyCode == 13
        withkeypress = false

    read = (query)->
        timer.postMessage 0
        isPlaying = false
        document.title = "タブ空文庫"
        $info.text "読み込み中です..."
        query = encodeURIComponent query
        jQuery.get "/q/#{query}", (res)->
            if res != ""
                play JSON.parse(res), 20
            else
                query = decodeURIComponent query
                $info.text "『#{query}』は見つかりませんでした。"

    datetimeformat = (dt)->
        yy = dt.getFullYear()
        mm = ("0" + (dt.getMonth()+1)).substr -2
        dd = ("0" + dt.getDate()   ).substr -2
        HH = ("0" + dt.getHours()  ).substr -2
        MM = ("0" + dt.getMinutes()).substr -2
        "#{yy}年#{mm}月#{dd}日 #{HH}時#{MM}分"

    bookinfo = (item)->
        $info.empty()
        $(document.createElement("span"))
            .text("#{item.title}/#{item.author} → ")
            .appendTo($info)
        $(document.createElement("a"))
            .attr("target", "aozora").attr("href", item.link).text("青空文庫で読む")
            .appendTo($info)
        $div = $(document.createElement("div"))
            .css("float", "right").appendTo($info)

        $(document.createElement("span")).text("読了予定: ").appendTo($div)
        $finished = $(document.createElement("span")).text(datetimeformat new Date).appendTo($div)
        $(document.createElement("span")).text(" / 残り: ").appendTo($div)
        $progress = $(document.createElement("span")).text("0分00秒").appendTo($div)

        [$finished, $progress]

    play = (item, length)->
        text = item.text
        [$finished, $progress] = bookinfo item
        [i, imax] = [0, text.length]

        timer.onmessage = ->
            if i < text.length
                document.title = text.substr i, length
                if i % 20
                    finished = new Date(+new Date() + readInterval * (imax - i))
                    $finished.text datetimeformat(finished)
                remain = ((imax - i) * readInterval / 1000)|0
                SS = ("0" + (remain % 60)).substr -2
                MM = (remain / 60)|0
                $progress.text "#{MM}分#{SS}秒"

                i += 1
            else
                document.title = "読了"
                timer.postMessage 0
        timer.postMessage readInterval
        isPlaying = true

    # random
    $("#random").on "click", ->
        cands = $(".booklist li")
        index = (Math.random() * cands.length)|0
        $(cands[index]).trigger "click"

    # speed
    (speed_li = $("#speed li")).each (i)->
        interval = [0, 600, 250, 75][i]
        $(this).on "click", =>
            speed_li.removeClass "selected"
            $(this).addClass "selected"
            readInterval = interval
            if isPlaying then timer.postMessage readInterval
    $(speed_li[2]).trigger "click"

    # booklist
    $(".booklist li").each ->
        $(this).on "click", =>
            query = $(this).attr("id")
            $query.val query
            read query

    # social buttons
    social_url = "http://tabzora.herokuapp.com/"
    sb = $("#social-button")
    $(".hatena", sb).socialbutton "hatena",
        button:"horizontal", url: social_url

    $(".tweet", sb).socialbutton "twitter",
        button:"horizontal", lang:"en", url: social_url

    $(".google_plus", sb).socialbutton "google_plusone",
        button:"medium", count:false, url: social_url

    $(".facebook", sb).socialbutton "facebook_like",
        button:"button_count", url: social_url
