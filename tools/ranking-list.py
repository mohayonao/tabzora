#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
import urllib

from BeautifulSoup import BeautifulSoup


RANKING_URL = "http://www.aozora.gr.jp/access_ranking/2012_03_txt.html"    
FORMAT = """      <li id="%(link)s">%(title)s/%(author)s</li>"""
LIMIT  = 100


def getFileLink(url):
    matches = re.match(r".*card(\d+)\.html$", url)
    if not matches: return
    
    card_num = matches.group(1)
    html = "".join( urllib.urlopen(url).readlines() )
    for a in BeautifulSoup(html).findAll("a"):
        matches = re.match(".*\.(\/files\/" + card_num + "_\d+\.html).*", str(a))
        if not matches: continue
        return url[:url.rfind("/")] + matches.group(1)


def main():
    html = "".join( urllib.urlopen(RANKING_URL).readlines() )
    for i, tr in enumerate(BeautifulSoup(html).findAll("tr")):
        td = tr.findAll("td")
        if len(td) != 4: continue
        title, author = td[1].find("a"), td[2].find("a")
        if not title or not author: continue

        link   = dict(title.attrs)["href"]
        title  = title.text
        author = author.text.replace(" ", "")
        
        link = getFileLink(link)
        if not link: continue

        print (FORMAT % dict(title=title, author=author, link=link)).encode("utf-8")
        
        if i == LIMIT: break

        
if __name__ == "__main__":
    main()
