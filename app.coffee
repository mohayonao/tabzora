fs      = require "fs"
path    = require "path"
http    = require "http"
express = require "express"
crypto  = require "crypto"
Iconv   = require("iconv").Iconv

do ->
    filepath = "#{__dirname}/devenv.json"
    if path.existsSync filepath
        for key, value of JSON.parse(fs.readFileSync(filepath, "utf-8"))
            process.env[key] = value
app = module.exports = express.createServer()

app.configure ->
    app.use express.bodyParser()
    app.use express.methodOverride()
    app.use app.router
    app.use express.static("#{__dirname}/public")

app.configure "development", ->
    app.use express.errorHandler(dumpExceptions:true, showStack:true)

app.configure "production", ->
    app.use express.errorHandler()

aozora_parse = (html)->
    re = /<h1 class="title">(.+?)<\/h1>(?:[\s\S]*?)<h2 class="author">(.+?)<\/h2>(?:[\s\S]*?)<div class="main_text">([\s\S]+)<div class="bibliographical_information">/
    matches = re.exec html
    if matches
        title  = matches[1]
        author = matches[2]
        text = matches[3].replace(/<ruby><rb>(.+?)<\/rb>.*?<\/ruby>/g, "$1")
        text = text.replace(/<.*?>/g, "")
        return {title:title, author:author, text:text}


get_aozora = (uri_path, callback)->
    uri = host:"mirror.aozora.gr.jp", path:uri_path

    sha1sum = crypto.createHash "sha1"
    sha1sum.update uri.path
    digest = sha1sum.digest "hex"
    filename = "#{__dirname}/cached/#{digest}.json"

    path.exists filename, (exists)->
        func = if exists then get_aozora_from_cache else get_aozora_from_web
        func uri, filename, callback


get_aozora_from_cache = (uri, filename, callback)->
    fs.readFile filename, "utf-8", (err, data)->
        callback if err then "" else data


get_aozora_from_web = (uri, filename, callback)->
    http.get uri, (res)->
        iconv = new Iconv("CP932", "UTF-8//TRANSLIT//IGNORE")
        body = []
        res.setEncoding "binary"
        res.on "data", (chunk)->
            body.push chunk
        res.on "end", ->
            body = new Buffer(body.join(""), "binary")
            html = iconv.convert(body).toString()
            item = aozora_parse(html)
            item.link = "http://www.aozora.gr.jp#{uri.path}"

            callback if not item then "" else
                item.text = item.text.replace(/\s/g, "")
                json = JSON.stringify(item)
                fs.writeFile filename, json
                json


search = (query, callback)->
    api_key = process.env.YAHOO_API_KEY

    uri = {}
    uri.host = "search.yahooapis.jp"
    uri.path = "/WebSearchService/V2/webSearch?appid=#{api_key}&query=#{query}&site=www.aozora.gr.jp&format=html&results=1"

    http.get uri, (res)->
        body = ""
        res.on "data", (chunk)->
            body += chunk
        res.on "end", ->
            re = /(http:\/\/www\.aozora\.gr\.jp\/cards\/(?:\d+)\/files\/(?:\d+_\d+)\.html)/gm
            matches = re.exec body
            callback if matches then matches[1].trim() else ""


app.get "/q/:query?", (req, res)->
    re = /^(?:http:\/\/www\.aozora\.gr\.jp)?(\/cards\/(?:\d+)\/files\/(?:\d+)_(?:\d+)\.html)$/
    matches = re.exec req.params.query

    if matches
        get_aozora matches[1], (result)-> res.send result
    else search req.params.query, (result)->
        matches = re.exec result
        if matches
            get_aozora matches[1], (result)-> res.send result
        else
            res.send ""

app.get "/", (req, res)->
    res.sendfile "#{__dirname}/views/index.html"

app.listen process.env.PORT || 3000
