module Main exposing (main)

import Browser exposing (Document)
import Html exposing (Html, a, div, img, li, nav, span, text, ul)
import Html.Attributes as A exposing (class)
import Pages.FixedTimeTask as FixedTimeTask
import Pages.Home as Home
import Pages.Media as Media
import Pages.Message as Message
import Pages.Register as Register
import Pages.RssTask as RssTask
import Pages.Tag as Tag
import Route exposing (Route)
import Shared exposing (Shared)
import Spa
import View exposing (View)


mappers : ( (a -> b) -> View a -> View b, (c -> d) -> View c -> View d )
mappers =
    ( View.map, View.map )


toDocument :
    Shared
    -> View (Spa.Msg Shared.Msg pageMsg)
    -> Document (Spa.Msg Shared.Msg pageMsg)
toDocument shared view =
    { title = view.title
    , body = [ view.body ]
    }


main =
    Spa.init
        { defaultView = View.defaultView
        , extractIdentity = Shared.user
        }
        |> Spa.addProtectedPage mappers Route.matchHome Home.page
        |> Spa.addProtectedPage mappers Route.matchMessage Message.page
        |> Spa.addProtectedPage mappers Route.matchFixedTimeTask FixedTimeTask.page
        |> Spa.addProtectedPage mappers Route.matchRssTask RssTask.page
        |> Spa.addProtectedPage mappers Route.matchTag Tag.page
        |> Spa.addProtectedPage mappers Route.matchMedia Media.page
        |> Spa.addPublicPage mappers Route.matchRegister Register.page
        |> Spa.application View.map
            { init = Shared.init
            , subscriptions = Shared.subscriptions
            , update = Shared.update
            , toRoute = Route.toRoute
            , toDocument = toDocument
            , protectPage = \_ -> Route.Register |> Route.toUrl
            }
        |> Browser.application
