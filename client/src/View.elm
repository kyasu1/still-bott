module View exposing (View, defaultView, map)

import Html exposing (Html, div)
import Html.Attributes exposing (class, src)
import Ui.Button


type alias View msg =
    { title : String
    , body : Html msg
    }


map : (msg1 -> msg) -> View msg1 -> View msg
map tomsg view =
    { title = view.title
    , body = Html.map tomsg view.body
    }


defaultView : View msg
defaultView =
    { title = "PAGE NOT FOUND"
    , body =
        div [ class "h-screen flex flex-col items-center justify-center" ]
            [ div [ class "my-4 text-4xl font-bold text-gray-500" ]
                [ Html.text
                    "404"
                ]
            , div [ class "my-4" ]
                [ Html.img
                    [ class "h-12"
                    , src "/assets/still_bott_logo.svg"
                    ]
                    []
                ]
            , div [ class "my-2 font-semibold text-xl" ] [ Html.text "ページが見つかりません" ]
            , div []
                [ Ui.Button.link "トップページへ"
                    [ Ui.Button.linkSpa "/"
                    , Ui.Button.transparent
                    ]
                ]
            ]
    }
