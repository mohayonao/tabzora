http    = require "http"
express = require "express"
Iconv   = require("iconv").Iconv

aozora_parse = (html)->

    re = /<h1 class="title">(.+?)<\/h1>(?:[\s\S]*?)<h2 class="author">(.+?)<\/h2>(?:[\s\S]*?)<div class="main_text">([\s\S]+)<div class="bibliographical_information">/
    matches = re.exec html
    if matches
        title  = matches[1]
        author = matches[2]
        text = matches[3].replace(/<ruby><rb>(.+?)<\/rb>.*?<\/ruby>/g, "$1")
        text = text.replace(/<.*?>/g, "")
        return {title:title, author:author, text:text}

app = module.exports = express.createServer()

app.configure ->
    app.use express.bodyParser()
    app.use express.methodOverride()
    app.use app.router
    app.use express.static("#{__dirname}/public")

app.get "/q/:query?", (req, res)->

    re = /^(?:http:\/\/www\.aozora\.gr\.jp)?(\/cards\/(?:\d+)\/files\/(?:\d+)_(?:\d+)\.html)$/
    matches = re.exec req.params.query

    if matches
        iconv = new Iconv("CP932", "UTF-8//TRANSLIT//IGNORE")
        options = host:"mirror.aozora.gr.jp", path:matches[1]

        http.get options, (xres)->
            body = []
            xres.setEncoding "binary"
            xres.on "data", (chunk)->
                body.push chunk
            xres.on "end", ()->
                body = new Buffer(body.join(""), "binary")
                html = iconv.convert(body).toString()
                item = aozora_parse(html)
                item.link = "http://www.aozora.gr.jp#{options.path}"
                if item
                    item.text = item.text.replace(/\s/g, "")
                    res.send JSON.stringify(item)
                else
                   res.send ""
    else
        res.send ""

app.get "/", (req, res)->
    res.sendfile "#{__dirname}/views/index.html"

app.listen process.env.PORT || 3000
