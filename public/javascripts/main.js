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
      var HH, MM, dd, mm, yy;
      yy = dt.getFullYear();
      mm = ("0" + (dt.getMonth() + 1)).substr(-2);
      dd = ("0" + dt.getDate()).substr(-2);
      HH = ("0" + dt.getHours()).substr(-2);
      MM = ("0" + dt.getMinutes()).substr(-2);
      return "" + yy + "年" + mm + "月" + dd + "日 " + HH + "時" + MM + "分";
    };
    bookinfo = function(item) {
      var $div, $finished, $progress;
      $info.empty();
      $(document.createElement("span")).text("" + item.title + "/" + item.author + " → ").appendTo($info);
      $(document.createElement("a")).attr("target", "aozora").attr("href", item.link).text("青空文庫で読む").appendTo($info);
      $div = $(document.createElement("div")).css("float", "right").appendTo($info);
      $(document.createElement("span")).text("読了予定: ").appendTo($div);
      $finished = $(document.createElement("span")).text(datetimeformat(new Date)).appendTo($div);
      $(document.createElement("span")).text(" / 残り: ").appendTo($div);
      $progress = $(document.createElement("span")).text("0分00秒").appendTo($div);
      return [$finished, $progress];
    };
    play = function(item, length, interval) {
      var $finished, $progress, i, imax, text, _ref1, _ref2;
      text = item.text;
      _ref1 = bookinfo(item), $finished = _ref1[0], $progress = _ref1[1];
      _ref2 = [0, text.length], i = _ref2[0], imax = _ref2[1];
      timer.onmessage = function() {
        var MM, SS, finished, remain;
        if (i < text.length) {
          document.title = text.substr(i, length);
          if (i % 20) {
            finished = new Date(+new Date() + interval * (imax - i));
            $finished.text(datetimeformat(finished));
          }
          remain = ((imax - i) * interval / 1000) | 0;
          SS = ("0" + (remain % 60)).substr(-2);
          MM = (remain / 60) | 0;
          $progress.text("" + MM + "分" + SS + "秒");
          return i += 1;
        } else {
          document.title = "読了!";
          return timer.postMessage(0);
        }
      };
      return timer.postMessage(interval);
    };
    $("#random").on("click", function() {
      var cands, index;
      cands = $(".booklist li");
      index = (Math.random() * cands.length) | 0;
      return $(cands[index]).trigger("click");
    });
    $(".booklist li").each(function() {
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
