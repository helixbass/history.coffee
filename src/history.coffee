_opt = ( str ) ->
 H.options \
  [ str ]

ie_lt_8 =
 $( "html.ie6, html.ie7" )
  .length > 0

ie_lt_7 =
 $( "html.ie6" )
  .length > 0

isEmptyObject = ( obj ) ->
 return no for name of obj
 yes

cloneObject = ( obj ) ->
 return JSON.parse JSON.stringify obj if obj
 {}

to_last = ( arr, \
            i=1 ) ->
 arr[ arr.length - i ]

unescapeString = ( str ) ->
 curr = str

 loop
   tmp = unescape curr
   return curr if tmp is curr
   curr = tmp

jQuery.urlHelpers = U =
  getRootUrl: ->
   "#{ document.location.protocol }//#{ document.location.hostname or document.location.host }#{ if document.location.port then ':' + document.location.port else '' }/"

  getBaseHref: ->
   $( "base" )
    .each ->
     return $( this )
             .attr( "href" )
             .replace( ///
                        [^/] +
                        $
                       ///,
                       "" )
             .replace( ///
                        / +
                        $
                       ///,
                       "" )
             .replace ///
                       (
                        . +
                       )
                      ///,
                      "$1/"
   ""

  getPageUrl: ->
   ( History?.getState( no,
                        no )
            ?.url or
      document.location
              .href )
    .replace( ///
               / +
               $
              ///,
              "" )
    .replace ///
              [^/] +
              $
             ///,
             ( part, \
               index, \
               string ) ->
              if ///
                  \.
                 ///
                  .test part
                part
              else
                "#{ part }/"

  getBasePageUrl: ->
   document.location
           .href
           .replace( ///
                      [#\?]
                      . *
                     ///,
                     "" )
           .replace( ///
                      [^/] +
                      $
                     ///,
                     ( part, \
                       index, \
                       string ) ->
                      if ///
                          [^/]
                          $
                         ///
                          .test part
                        ""
                      else
                        part )
           .replace( ///
                      / +
                      $
                     ///,
                     "" ) +
    "/"

  getBaseUrl: ->
   U.getBaseHref() or
    U.getBasePageUrl() or
    U.getRootUrl()

  getFullUrl: ( url, \
                allowBaseHref=yes ) ->
   first=url.substring 0,
                       1
   ( if ///
         [a-z] +
         \://
        ///
         .test url
       url
     else if first is "/"
       U.getRootUrl() +
        url.replace ///
                     ^
                     / +
                    ///,
                    ""
     else if first is "#"
       U.getPageUrl()
        .replace( ///
                   #
                   . *
                  ///,
                  "" ) +
        url
     else if first is "?"
       U.getPageUrl()
        .replace( ///
                   [\?#]
                   . *
                  ///,
                  "" ) +
        url
      else if allowBaseHref
        U.getBaseUrl() +
         url.replace ///
                      ^
                      (
                       \./
                      ) +
                     ///,
                     ""
      else
        U.getBasePageUrl() +
         url.replace ///
                      ^
                      (
                       \./
                      ) +
                     ///,
                     "" )
    .replace ///
              \#
              $
             ///,
             ""

  getShortUrl: ( url ) ->
   trimmed =
    ( if History?.emulated
                 .pushState
        url.replace U.getBaseUrl(),
                    ""
      else
        url )
     .replace U.getRootUrl(),
              "/"

   ( if U.isTraditionalAnchor trimmed 
       "./#{ trimmed }"
     else
       trimmed )
    .replace( ///
               ^
               (
                \./
               ) +
              ///g,
              "./" )
    .replace ///
              \#
              $
             ///,
             ""

  isTraditionalAnchor: ( url_or_hash ) ->
   not ///
        [/\?\.]
       ///
        .test url_or_hash

jQuery.History = H =
  init: ->
   H.initCore()
   H.initHtml4?()

  options:
      hashChangeInterval:
       100
      safariPollInterval:
       500
      doubleCheckInterval:
       500
      storeInterval:
       1000
      busyDelay:
       250
      debug:
       no
      initialTitle:
       document.title

  intervalList:
   []

  clearAllIntervals: ->
   clearInterval iv for iv in H.intervalList
   no

  debug: ( message, \
           args... ) ->
   H.log( message,
          args... ) if _opt "debug"

  log: ( message, \
         args... ) ->
   console?.debug
          ?.apply( console,
                   [ message,
                     args ] ) ?
    console?.log
           ?.apply( console,
                    [ message,
                      args ] )

   message = "\n#{ message }\n"

   message += ( try
                  "\n#{ JSON.stringify arg }\n"
                catch Exception
                  no ) for arg in args

   if ( $log = $ log ).length
     $log.val += "#{ message }\n-----\n"
     # XXX scroll
   else
     alert message if not console?.log

   yes

  emulated:
      pushState:
       not ( history and
              history.pushState and
              history.replaceState and
              not ( ///
                     \s
                     Mobile/
                     (
                      [1-7]
                      [a-z]
                       |
                      (
                       8
                       (
                        [abcde]
                         |
                        f
                        (
                         1
                         [0-8]
                        )
                       )
                      )
                     )
                    ///i
                     .test navigator.userAgent or
                   ///
                    AppleWebKit/5
                    (
                     [0-2]
                      |
                     3
                     [0-2]
                    )
                   ///i
                    .test navigator.userAgent ))

      hashChange:
       not ( "onhashchange" of window or
              "onhashchange" of document ) or
        ie_lt_8

  enabled:
   not H.emulated.pushState

  bugs:
   setHash:
    H.enabled and
     navigator.vendor is "Apple Computer, Inc." and
     ///
      AppleWebKit/5
      (
       [0-2]
        |
       3
       [0-3]
      )
     ///
      .test navigator.userAgent
   safariPoll:
    H.bugs.setHash 
   ieDoubleCheck:
    ie_lt_8
   hashEscape:
    ie_lt_7

  store:
   {}

  idToState:
   {}

  stateToId:
   {}

  urlToId:
   {}

  storedStates:
   []

  savedStates:
   []

  normalizeStore: ->
   H.store
    .idToState or=
    {}
   H.store
    .stateToId or=
    {}
   H.store
    .urlToId or=
    {}

  initCore: ->
   no

  getState: ( friendly=yes \
            , create=yes ) ->
    

  generateUniqueId: () ->
   loop
     id = ( new Date())
           .getTime() +
           String( Math.random())
            .replace /\D/g,
                     ""
     return id unless H.idToState[ id ]? or
                       H.store
                        .idToState[ id ]?
   null

  storeId: ( id, \
             str, \
             state ) ->
   H.stateToId[ str ] = id
   H.idToState[ id ] = state
   id

  createId: ( str, \
              state ) ->
   H.storeId H.generateUniqueId(),
             str,
             state

  extractId: ( url_or_hash ) ->
   ///
    . *
    \&_suid=
    (
     [0-9] +
    )
    $
   ///
    .exec( url_or_hash )?[ 1 ] or
    no

  getStateById: ( id ) ->
   return undefined unless id
   id = String( id )

   H.idToState[ id ] or
    H.store
     .idToState[ id ] or
    undefined

  createStateObject: ( data, \
                       title, \
                       url ) ->
   H.normalizeState data:
                     data
                    title:
                     title
                    url:
                     url

  getIdByUrl: ( url ) ->
   H.urlToId[ url ] or
    H.store
     .urlToId[ url ] or
    undefined

  extractState: ( url_or_hash, \
                  create=no ) ->
   H.getStateById( H.extractId url_or_hash ) ?
    (( full_url ) ->
     H.getStateById( H.getIdByUrl full_url ) ?
      if create and not H.isTraditionalAnchor url_or_hash
          H.createStateObject null,
                              null,
                              full_url
      else
          null ) U.getFullUrl url_or_hash

  getStateString: ( nu ) ->
   JSON.stringify data:
                   nu.data
                  title:
                   nu.title
                  url:
                   nu.url

  getIdByState: ( nu ) ->
   H.extractId( nu.url ) or
    (( str ) ->
      H.stateToId[ str ] ?
       H.store
        .stateToId[ str ] ?
       H.createId str,
                  nu ) H.getStateString nu

  hasUrlDuplicate: ( nu ) ->
   H.extractState( nu.url )
    ?.id isnt
    nu.id

  normalizeState: ( old={} ) ->
    return old if old.normalized?

    old.data ?= {}

    nu = 
      normalized:
       yes

      title:
       old.title or
        ""

      url:
       U.getFullUrl unescapeString old.url or
                                    document.location
                                            .href

      data:
       cloneObject old.data

    cleanUrl = ( url ) ->
     url
      .replace ///
                \? ?
                \&_suid
                . *
               ///,
               ""

    appendQuery = ( url, \
                    id ) ->
     "#{ url }#{ if not /\?/.test url then '?' else '' }&_suid=#{ id }"

    $.extend nu,
             hash:
              H.getShortUrl nu.url
             id:
              H.getIdByState nu
             cleanUrl:
              cleanUrl nu.url

    nu.url = nu.cleanUrl

    if nu.title or not isEmptyObject nu.data
        nu.hash = appendQuery cleanUrl( U.getShortUrl nu.url ),
                              nu.id

    nu.hashedUrl = H.getFullUrl nu.hash

    nu.url = nu.hashedUrl if ( H.emulated
                                .pushState or
                                H.bugs
                                 .safariPoll ) and
                              H.hasUrlDuplicate nu

    nu

  storeState: ( nu ) ->
   H.urlToId[ nu.url ] = nu.id
   H.storedStates
    .push cloneObject nu

   nu

  getLastSavedState: () ->
   to_last H.savedStates

  getLastStoredState: () ->
   to_last H.storedStates

  isLastSavedState: ( nu ) ->
   return nu.id is H.getLastSavedState()
                    .id if H.savedStates
                            .length

   no

  saveState: ( nu ) ->
   return no if H.isLastSavedState nu

   H.savedStates
    .push cloneObject nu

   yes

  getStateByIndex: ( i ) ->
   return to_last H.savedStates unless i?

   if i < 0
       to_last H.savedStates,
               -i
   else
       H.savedStates[ i ]

  getHashByState: ( state ) ->
   H.normalizeState( state )
    .hash

  getStateId: ( state ) ->
   H.normalizeState( state )
    .id
