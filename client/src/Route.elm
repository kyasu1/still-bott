module Route exposing
    ( Route(..)
    , matchAny
    , matchFixedTimeTask
    , matchHome
    , matchLog
    , matchMedia
    , matchMessage
    , matchRegister
    , matchRssTask
    , matchTag
    , route
    , toRoute
    , toUrl
    )

import Url exposing (Url)
import Url.Parser exposing ((<?>), Parser, map, oneOf, parse, s, top)


type Route
    = Home
    | Message
    | FixedTimeTask
    | RssTask
    | Tag
    | Media
    | Log
    | Register
    | NotFound Url


route : Parser (Route -> a) a
route =
    oneOf
        [ map Register <| s "register"
        , map Message <| s "message"
        , map FixedTimeTask <| s "fixed-time-task"
        , map RssTask <| s "rss-task"
        , map Tag <| s "tag"
        , map Media <| s "media"
        , map Log <| s "log"
        , map Home top
        ]


toRoute : Url -> Route
toRoute url =
    url
        |> parse route
        |> Maybe.withDefault (NotFound url)


toUrl : Route -> String
toUrl r =
    case r of
        Home ->
            "/"

        Message ->
            "/message"

        FixedTimeTask ->
            "/fixed-time-task"

        RssTask ->
            "/rss-task"

        Tag ->
            "/tag"

        Media ->
            "/media"

        Log ->
            "/log"

        Register ->
            "/register"

        NotFound url ->
            Url.toString url


matchAny : Route -> Route -> Maybe ()
matchAny any r =
    if any == r then
        Just ()

    else
        Nothing


matchHome : Route -> Maybe ()
matchHome =
    matchAny Home


matchMessage : Route -> Maybe ()
matchMessage =
    matchAny Message


matchFixedTimeTask : Route -> Maybe ()
matchFixedTimeTask =
    matchAny FixedTimeTask


matchRssTask : Route -> Maybe ()
matchRssTask =
    matchAny RssTask


matchTag : Route -> Maybe ()
matchTag =
    matchAny Tag


matchMedia : Route -> Maybe ()
matchMedia =
    matchAny Media


matchLog : Route -> Maybe ()
matchLog =
    matchAny Log


matchRegister : Route -> Maybe ()
matchRegister =
    matchAny Register
