require "./test_helper.js"
extend global, require "./test_chrome_stubs.js"
extend(global, require "../../lib/utils.js")
Utils.getCurrentVersion = -> '1.43'
extend(global, require "../../lib/settings.js")

context "isUrl",
  should "accept valid URLs", ->
    assert.isTrue Utils.isUrl "www.google.com"
    assert.isTrue Utils.isUrl "www.bbc.co.uk"
    assert.isTrue Utils.isUrl "yahoo.com"
    assert.isTrue Utils.isUrl "nunames.nu"
    assert.isTrue Utils.isUrl "user:pass@ftp.xyz.com/test"

    assert.isTrue Utils.isUrl "localhost/index.html"
    assert.isTrue Utils.isUrl "127.0.0.1:8192/test.php"

    # IPv6
    assert.isTrue Utils.isUrl "[::]:9000"

    # Long TLDs
    assert.isTrue Utils.isUrl "illinois.state.museum"
    assert.isTrue Utils.isUrl "eqt5g4fuenphqinx.onion"

    # Internal URLs.
    assert.isTrue Utils.isUrl "moz-extension://c66906b4-3785-4a60-97bc-094a6366017e/pages/options.html"

  should "reject invalid URLs", ->
    assert.isFalse Utils.isUrl "a.x"
    assert.isFalse Utils.isUrl "www-domain-tld"

context "convertToUrl",
  should "detect and clean up valid URLs", ->
    assert.equal "http://www.google.com/", Utils.convertToUrl("http://www.google.com/")
    assert.equal "http://www.google.com/", Utils.convertToUrl("    http://www.google.com/     ")
    assert.equal "http://www.google.com", Utils.convertToUrl("www.google.com")
    assert.equal "http://google.com", Utils.convertToUrl("google.com")
    assert.equal "http://localhost", Utils.convertToUrl("localhost")
    assert.equal "http://xyz.museum", Utils.convertToUrl("xyz.museum")
    assert.equal "chrome://extensions", Utils.convertToUrl("chrome://extensions")
    assert.equal "http://user:pass@ftp.xyz.com/test", Utils.convertToUrl("user:pass@ftp.xyz.com/test")
    assert.equal "http://127.0.0.1", Utils.convertToUrl("127.0.0.1")
    assert.equal "http://127.0.0.1:8080", Utils.convertToUrl("127.0.0.1:8080")
    assert.equal "http://[::]:8080", Utils.convertToUrl("[::]:8080")
    assert.equal "view-source:    0.0.0.0", Utils.convertToUrl("view-source:    0.0.0.0")
    assert.equal "javascript:alert('25 % 20 * 25 ');", Utils.convertToUrl "javascript:alert('25 % 20 * 25%20');"

  should "convert non-URL terms into search queries", ->
    assert.equal "https://www.google.com/search?q=google", Utils.convertToUrl("google")
    assert.equal "https://www.google.com/search?q=go+ogle.com", Utils.convertToUrl("go ogle.com")
    assert.equal "https://www.google.com/search?q=%40twitter", Utils.convertToUrl("@twitter")

context "isPath",
  should "accept valid paths", ->
    assert.isTrue Utils.isPath "/"
    assert.isTrue Utils.isPath "/path"
    assert.isTrue Utils.isPath "./"
    assert.isTrue Utils.isPath "./path"
    assert.isTrue Utils.isPath ".."
    assert.isTrue Utils.isPath "../path"
    assert.isTrue Utils.isPath "../.."
    assert.isTrue Utils.isPath "/path/../path"

  should "reject invalid paths", ->
    assert.isFalse Utils.isPath "http://127.0.0.1:8080"
    assert.isFalse Utils.isPath "search query"
    assert.isFalse Utils.isPath "..."
    assert.isFalse Utils.isPath "..path"

context "resolvePath",
  should "resolve absolute path", ->
    assert.equal "http://8.8.8.8:80", Utils.resolvePath "http://8.8.8.8:80/ws", "/"
    assert.equal "http://8.8.8.8:80/path", Utils.resolvePath "http://8.8.8.8:80/ws", "/path"
    assert.equal "file:///", Utils.resolvePath "file:///", "/"    
    assert.equal "file:///path", Utils.resolvePath "file:///", "/path"    
  should "resolve simple relative path", ->
    assert.equal "http://8.8.8.8:80/ws", Utils.resolvePath "http://8.8.8.8:80/ws", "./"
    assert.equal "http://8.8.8.8:80/ws", Utils.resolvePath "http://8.8.8.8:80/ws#hash", "./"
    assert.equal "http://8.8.8.8:80/ws", Utils.resolvePath "http://8.8.8.8:80/ws?query", "./"
    assert.equal "http://8.8.8.8:80/ws/path", Utils.resolvePath "http://8.8.8.8:80/ws", "./path"
    assert.equal "http://8.8.8.8:80/ws/path", Utils.resolvePath "http://8.8.8.8:80/ws#hash", "./path"
    assert.equal "http://8.8.8.8:80/ws/path", Utils.resolvePath "http://8.8.8.8:80/ws?query", "./path"
  should "resolve 'level up' relative path", ->
    assert.equal "http://8.8.8.8:80", Utils.resolvePath "http://8.8.8.8:80/ws", ".."
    assert.equal "http://8.8.8.8:80", Utils.resolvePath "http://8.8.8.8:80/ws#hash", ".."
    assert.equal "http://8.8.8.8:80", Utils.resolvePath "http://8.8.8.8:80/ws?query", ".."
    assert.equal "http://8.8.8.8:80/path", Utils.resolvePath "http://8.8.8.8:80/ws", "../path"
    assert.equal "http://8.8.8.8:80", Utils.resolvePath "http://8.8.8.8:80/ws", "../.."
  should "resolve complex relative path", ->
    assert.equal "http://8.8.8.8:80/path", Utils.resolvePath "http://8.8.8.8:80/ws", "/path/../path"
    assert.equal "http://8.8.8.8:80/path", Utils.resolvePath "http://8.8.8.8:80/ws", "./path/../../path"
    assert.equal "http://8.8.8.8:80/path", Utils.resolvePath "http://8.8.8.8:80/ws", "../path/../path"
  should "preserve trailing slash in path", ->
    assert.equal "https://ftp.mozilla.org/pub/", Utils.resolvePath "https://ftp.mozilla.org/favicon.ico", "/pub/"    
    assert.equal "https://ftp.mozilla.org/pub/firefox/", Utils.resolvePath "https://ftp.mozilla.org/pub/", "./firefox/"    
    assert.equal "https://ftp.mozilla.org/pub/", Utils.resolvePath "https://ftp.mozilla.org/pub/firefox/", "../"    

context "extractQuery",
  should "extract queries from search URLs", ->
    assert.equal "bbc sport 1", Utils.extractQuery "https://www.google.ie/search?q=%s", "https://www.google.ie/search?q=bbc+sport+1"
    assert.equal "bbc sport 2", Utils.extractQuery "http://www.google.ie/search?q=%s", "https://www.google.ie/search?q=bbc+sport+2"
    assert.equal "bbc sport 3", Utils.extractQuery "https://www.google.ie/search?q=%s", "http://www.google.ie/search?q=bbc+sport+3"
    assert.equal "bbc sport 4", Utils.extractQuery "https://www.google.ie/search?q=%s", "http://www.google.ie/search?q=bbc+sport+4&blah"

  should "extract not queries from incorrect search URLs", ->
    assert.isFalse Utils.extractQuery "https://www.google.ie/search?q=%s&foo=bar", "https://www.google.ie/search?q=bbc+sport"

context "hasChromePrefix",
  should "detect chrome prefixes of URLs", ->
    assert.isTrue Utils.hasChromePrefix "about:foobar"
    assert.isTrue Utils.hasChromePrefix "view-source:foobar"
    assert.isTrue Utils.hasChromePrefix "chrome-extension:foobar"
    assert.isTrue Utils.hasChromePrefix "data:foobar"
    assert.isTrue Utils.hasChromePrefix "data:"
    assert.isFalse Utils.hasChromePrefix ""
    assert.isFalse Utils.hasChromePrefix "about"
    assert.isFalse Utils.hasChromePrefix "view-source"
    assert.isFalse Utils.hasChromePrefix "chrome-extension"
    assert.isFalse Utils.hasChromePrefix "data"
    assert.isFalse Utils.hasChromePrefix "data :foobar"

context "hasJavascriptPrefix",
  should "detect javascript: URLs", ->
    assert.isTrue Utils.hasJavascriptPrefix "javascript:foobar"
    assert.isFalse Utils.hasJavascriptPrefix "http:foobar"

context "decodeURIByParts",
  should "decode javascript: URLs", ->
    assert.equal "foobar", Utils.decodeURIByParts "foobar"
    assert.equal " ", Utils.decodeURIByParts "%20"
    assert.equal "25 % 20 25 ", Utils.decodeURIByParts "25 % 20 25%20"

context "isUrl",
  should "identify URLs as URLs", ->
    assert.isTrue Utils.isUrl "http://www.example.com/blah"

  should "identify non-URLs and non-URLs", ->
    assert.isFalse Utils.isUrl "http://www.example.com/ blah"

context "Function currying",
  should "Curry correctly", ->
    foo = (a, b) -> "#{a},#{b}"
    assert.equal "1,2", foo.curry()(1,2)
    assert.equal "1,2", foo.curry(1)(2)
    assert.equal "1,2", foo.curry(1,2)()

context "compare versions",
  should "compare correctly", ->
    assert.equal 0, Utils.compareVersions("1.40.1", "1.40.1")
    assert.equal 0, Utils.compareVersions("1.40", "1.40.0")
    assert.equal 0, Utils.compareVersions("1.40.0", "1.40")
    assert.equal -1, Utils.compareVersions("1.40.1", "1.40.2")
    assert.equal -1, Utils.compareVersions("1.40.1", "1.41")
    assert.equal -1, Utils.compareVersions("1.40", "1.40.1")
    assert.equal 1, Utils.compareVersions("1.41", "1.40")
    assert.equal 1, Utils.compareVersions("1.41.0", "1.40")
    assert.equal 1, Utils.compareVersions("1.41.1", "1.41")

context "makeIdempotent",
  setup ->
    @count = 0
    @func = Utils.makeIdempotent (n = 1) => @count += n

  should "call a function once", ->
    @func()
    assert.equal 1, @count

  should "call a function once with an argument", ->
    @func 2
    assert.equal 2, @count

  should "not call a function a second time", ->
    @func()
    assert.equal 1, @count

  should "not call a function a second time", ->
    @func()
    assert.equal 1, @count
    @func()
    assert.equal 1, @count

context "distinctCharacters",
  should "eliminate duplicate characters", ->
    assert.equal "abc", Utils.distinctCharacters "bbabaabbacabbbab"

context "escapeRegexSpecialCharacters",
  should "escape regexp special characters", ->
    str = "-[]/{}()*+?.^$|"
    regexp = new RegExp Utils.escapeRegexSpecialCharacters str
    assert.isTrue regexp.test str

context "extractQuery",
  should "extract the query terms from a URL", ->
    url = "https://www.google.ie/search?q=star+wars&foo&bar"
    searchUrl = "https://www.google.ie/search?q=%s"
    assert.equal "star wars", Utils.extractQuery searchUrl, url

  should "require trailing URL components", ->
    url = "https://www.google.ie/search?q=star+wars&foo&bar"
    searchUrl = "https://www.google.ie/search?q=%s&foobar=x"
    assert.equal null, Utils.extractQuery searchUrl, url

  should "accept trailing URL components", ->
    url = "https://www.google.ie/search?q=star+wars&foo&bar&foobar=x"
    searchUrl = "https://www.google.ie/search?q=%s&foobar=x"
    assert.equal "star wars", Utils.extractQuery searchUrl, url

