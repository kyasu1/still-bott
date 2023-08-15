module Dialog exposing (closeDialog, confirm, error, hidden, loading, modal, openDialog)

import Html exposing (Html, div, text)
import Html.Attributes as A exposing (class)
import InteropDefinitions
import InteropPorts
import Ui.Button


openDialog : String -> Cmd msg
openDialog id =
    InteropPorts.fromElm (InteropDefinitions.OpenDialog id)


closeDialog : String -> Cmd msg
closeDialog id =
    InteropPorts.fromElm (InteropDefinitions.CloseDialog id)


hidden : String -> Html msg
hidden id =
    base
        []


loading : String -> Html msg
loading id =
    base
        [ text "Loading" ]


confirm : { message : String, ok : msg, cancel : msg } -> Html msg
confirm { message, ok, cancel } =
    base
        [ div [ class "text-center my-4" ] [ text message ]
        , div [ class "flex items-center justify-center space-x-4" ]
            [ div [ class "w-32" ]
                [ Ui.Button.button "キャンセル"
                    [ Ui.Button.onClick cancel
                    , Ui.Button.small
                    , Ui.Button.outline
                    , Ui.Button.fillContainerWidth
                    ]
                ]
            , div [ class "w-32" ]
                [ Ui.Button.button "実行"
                    [ Ui.Button.onClick ok
                    , Ui.Button.small
                    , Ui.Button.fillContainerWidth
                    ]
                ]
            ]
        ]


error : { message : String, ok : msg } -> Html msg
error { message, ok } =
    base
        [ div [] [ text message ]
        , div [ class "flex items-center justify-center space-x-4" ]
            [ div [ class "w-32" ] [ Ui.Button.button "確認" [ Ui.Button.onClick ok ] ]
            ]
        ]


modal : List (Html msg) -> Html msg
modal contents =
    base
        contents


base : List (Html msg) -> Html msg
base contents =
    Html.node "dialog"
        [ A.id "dialog"
        , class "w-full md:w-3/4 max-w-4xl backdrop:bg-gray-500 backdrop:opacity-50 p-4 open:bg-white open:shadow-xl rounded-md"

        -- , Html.Events.stopPropagationOn "click" (JD.succeed ( NoOp, True ))
        -- , Html.Events.preventDefaultOn "click" (JD.succeed ( NoOp, True ))
        -- , onClick ClickedCloseDialog
        ]
    <|
        contents
