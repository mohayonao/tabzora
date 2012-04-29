// Generated by CoffeeScript 1.3.1
(function() {
  "use strict";

  jQuery(function() {
    var $info, $query, NOP, bookinfo, datetimeformat, play, read, sb, social_url, timer, withkeypress, _ref;
    NOP = function() {};
    if (/mac.*firefox/i.test(navigator.userAgent)) {
      setInterval(NOP, 500);
    }
    _ref = [$("#query"), $("#info")], $query = _ref[0], $info = _ref[1];
    timer = new Worker("/javascripts/muteki-timer.js");
    withkeypress = false;
    $query.on("keypress", function() {
      return withkeypress = true;
    });
    $query.on("keyup", function(e) {
      var query;
      query = this.value.trim();
      if (query.length && withkeypress && e.keyCode === 13) {
        read(query);
      }
      return withkeypress = false;
    });
    read = function(query) {
      timer.postMessage(0);
      document.title = "タブ空文庫";
      $info.text("読み込み中です...");
      query = encodeURIComponent(query);
      return jQuery.get("/q/" + query, function(res) {
        if (res !== "") {
          return play(JSON.parse(res), 20, 250);
        } else {
          query = decodeURIComponent(query);
          return $info.text("『" + query + "』は見つかりませんでした。");
        }
      });
    };
    datetimeformat = function(dt) {
      var HH, MM, SS, dd, mm, yy;
      yy = dt.getFullYear();
      mm = ("0" + (dt.getMonth() + 1)).substr(-2);
      dd = ("0" + dt.getDate()).substr(-2);
      HH = ("0" + dt.getHours()).substr(-2);
      MM = ("0" + dt.getMinutes()).substr(-2);
      SS = ("0" + dt.getSeconds()).substr(-2);
      return "" + yy + "年" + mm + "月" + dd + "日 " + HH + "時" + MM + "分" + SS + "秒";
    };
    bookinfo = function(item, finished) {
      var $div;
      $info.empty();
      $(document.createElement("span")).text("" + item.title + "/" + item.author + " → ").appendTo($info);
      $(document.createElement("a")).attr("target", "aozora").attr("href", item.link).text("青空文庫で読む").appendTo($info);
      $div = $(document.createElement("div")).css("float", "right").appendTo($info);
      $(document.createElement("span")).text("読了予定: " + (datetimeformat(finished)) + " / 残り: ").appendTo($div);
      return $(document.createElement("span")).text("00分00秒").appendTo($div);
    };
    play = function(item, length, interval) {
      var $progress, finished, i, imax, text, _ref1;
      text = item.text;
      finished = new Date(+new Date() + interval * text.length);
      $progress = bookinfo(item, finished);
      _ref1 = [0, text.length], i = _ref1[0], imax = _ref1[1];
      timer.onmessage = function() {
        var MM, SS, remain;
        if (i < text.length) {
          document.title = text.substr(i, length);
          i += 1;
          remain = ((finished - +new Date()) / 1000) | 0;
          SS = ("0" + (remain % 60)).substr(-2);
          MM = (remain / 60) | 0;
          return $progress.text("" + MM + "分" + SS + "秒");
        } else {
          document.title = "読了!";
          return timer.postMessage(0);
        }
      };
      return timer.postMessage(interval);
    };
    $("#booklist li").each(function() {
      var _this = this;
      return $(this).on("click", function() {
        var query;
        query = $(_this).attr("id");
        $query.val(query);
        return read(query);
      });
    });
    social_url = "http://tabzora.herokuapp.com/";
    sb = $("#social-button");
    $(".hatena", sb).socialbutton("hatena", {
      button: "horizontal",
      url: social_url
    });
    $(".tweet", sb).socialbutton("twitter", {
      button: "horizontal",
      lang: "en",
      url: social_url
    });
    $(".google_plus", sb).socialbutton("google_plusone", {
      button: "medium",
      count: false,
      url: social_url
    });
    return $(".facebook", sb).socialbutton("facebook_like", {
      button: "button_count",
      url: social_url
    });
  });

}).call(this);
