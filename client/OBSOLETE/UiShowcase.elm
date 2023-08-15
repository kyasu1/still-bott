module Pages.UiShowcase exposing (..)

import Effect exposing (Effect)
import Html exposing (div, text)
import Html.Attributes exposing (class)
import Shared exposing (Shared, subscriptions)
import Spa.Page
import Ui
import View exposing (View)


page shared =
    Spa.Page.element
        { init = always init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    { size : Ui.Size }


type Msg
    = NoOp
    | SizePicked Ui.Size


init : ( Model, Effect sharedMsg Msg )
init =
    ( { size = Ui.Md }, Effect.none )


update : Msg -> Model -> ( Model, Effect sharedMsg Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )

        SizePicked size ->
            ( { model | size = size }, Effect.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> View Msg
view model =
    { title = "Ui Showcase"
    , body =
        div [ class "space-y-4" ]
            [ div [ class "py-4" ]
                [ Ui.radioGroup
                    { label = "サイズ"
                    , name = "ui-size"
                    , options =
                        [ Ui.RadioGroupOption Ui.Xs "Xs"
                        , Ui.RadioGroupOption Ui.Sm "Sm"
                        , Ui.RadioGroupOption Ui.Md "Md"
                        , Ui.RadioGroupOption Ui.Lg "Lg"
                        , Ui.RadioGroupOption Ui.Xl "Xl"
                        ]
                    , picked = model.size
                    , onPick = SizePicked
                    }
                ]
            , div [ class "space-y-2 w-full" ]
                [ div [ class "flex space-x-2" ]
                    [ Ui.button Ui.Solid Ui.Primary model.size { onPress = Nothing, label = text "ボタン" }
                    , Ui.button Ui.Solid Ui.Secondary model.size { onPress = Nothing, label = text "ボタン" }
                    , Ui.button Ui.Solid Ui.Black model.size { onPress = Nothing, label = text "ボタン" }
                    ]
                , div [ class "space-x-2" ]
                    [ Ui.button Ui.Outline Ui.Primary model.size { onPress = Nothing, label = text "ボタン" }
                    , Ui.button Ui.Outline Ui.Secondary model.size { onPress = Nothing, label = text "ボタン" }
                    , Ui.button Ui.Outline Ui.Black model.size { onPress = Nothing, label = text "ボタン" }
                    ]
                , div [ class "space-x-2" ]
                    [ Ui.button Ui.Ghost Ui.Primary model.size { onPress = Nothing, label = text "ボタン" }
                    , Ui.button Ui.Ghost Ui.Secondary model.size { onPress = Nothing, label = text "ボタン" }
                    , Ui.button Ui.Ghost Ui.Black model.size { onPress = Nothing, label = text "ボタン" }
                    ]
                , div [ class "space-x-2" ]
                    [ Ui.button Ui.Link Ui.Primary model.size { onPress = Nothing, label = text "ボタン" }
                    , Ui.button Ui.Link Ui.Secondary model.size { onPress = Nothing, label = text "ボタン" }
                    , Ui.button Ui.Link Ui.Black model.size { onPress = Nothing, label = text "ボタン" }
                    ]
                ]
            , div [ class "space-y-2" ]
                [ div [ class "space-x-2" ]
                    [ Ui.button Ui.Solid Ui.Primary model.size { onPress = Just NoOp, label = text "ボタン" }
                    , Ui.button Ui.Solid Ui.Secondary model.size { onPress = Just NoOp, label = text "ボタン" }
                    , Ui.button Ui.Solid Ui.Black model.size { onPress = Just NoOp, label = text "ボタン" }
                    ]
                , div [ class "space-x-2" ]
                    [ Ui.button Ui.Outline Ui.Primary model.size { onPress = Just NoOp, label = text "ボタン" }
                    , Ui.button Ui.Outline Ui.Secondary model.size { onPress = Just NoOp, label = text "ボタン" }
                    , Ui.button Ui.Outline Ui.Black model.size { onPress = Just NoOp, label = text "ボタン" }
                    ]
                , div [ class "space-x-2" ]
                    [ Ui.button Ui.Ghost Ui.Primary model.size { onPress = Just NoOp, label = text "ボタン" }
                    , Ui.button Ui.Ghost Ui.Secondary model.size { onPress = Just NoOp, label = text "ボタン" }
                    , Ui.button Ui.Ghost Ui.Black model.size { onPress = Just NoOp, label = text "ボタン" }
                    ]
                , div [ class "space-x-2" ]
                    [ Ui.button Ui.Link Ui.Primary model.size { onPress = Just NoOp, label = text "ボタン" }
                    , Ui.button Ui.Link Ui.Secondary model.size { onPress = Just NoOp, label = text "ボタン" }
                    , Ui.button Ui.Link Ui.Black model.size { onPress = Just NoOp, label = text "ボタン" }
                    ]
                ]
            ]
    }
