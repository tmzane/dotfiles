#!/usr/bin/osascript -l JavaScript

nnw = Application("NetNewsWire")
acc = nnw.accounts().find(a => a.accounttype() === "onmymac")
opml = acc.opmlRepresentation()

se = Application("System Events")
home = se.currentUser.homeDirectory()
path = home + "/backup/rss.opml"

// https://bru6.de/jxa/jxa-basics/#writing-and-reading-unicode-data
str = $.NSString.alloc.initWithUTF8String(opml)
str.writeToFileAtomicallyEncodingError(path, true, $.NSUTF8StringEncoding, null)
