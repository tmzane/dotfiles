#!/usr/bin/osascript -l JavaScript

// This script exports RSS feeds from the NetNewsWire reader.
//
// Usage: export_rss_feeds.js <path/to/rss.opml>

function run(argv) {
    if (argv.length < 1) {
        console.log("too few arguments")
        return
    }

    app = Application("NetNewsWire")
    acc = app.accounts().find(a => a.accounttype() === "onmymac")
    opml = acc.opmlRepresentation()

    // https://bru6.de/jxa/jxa-basics/#writing-and-reading-unicode-data
    str = $.NSString.alloc.initWithUTF8String(opml)
    str.writeToFileAtomicallyEncodingError(argv[0], true, $.NSUTF8StringEncoding, null)
}
