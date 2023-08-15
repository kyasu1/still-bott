module Pages.Home exposing (page)

import Common
import Dialog
import Effect exposing (Effect)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Html exposing (Html, caption, div, h2, img, table, tbody, td, text, th, thead, tr)
import Html.Attributes as A exposing (class)
import Http
import InteropDefinitions exposing (Flags)
import Model.Dashboard as Dashboard exposing (Dashboard)
import Model.User exposing (User)
import Pages.Register exposing (Model(..), Msg(..))
import Route
import Shared exposing (Shared)
import Spa.Page
import Ui.Button
import View exposing (View)


page : Shared -> User -> Spa.Page.Page () Shared.Msg (View Msg) Model Msg
page shared user =
    Spa.Page.element
        { init = init user
        , update = update shared
        , subscriptions = \_ -> Sub.none
        , view = view shared
        }



-- subscriptions : Model -> Sub Msg
-- subscriptions model =
--     InteropPorts.toElm
--         |> Sub.map
--             GotSubscription


init : User -> () -> ( Model, Effect Shared.Msg Msg )
init user flags =
    ( Loading user, Shared.makeQuery user (Dashboard.query user.id) GotDashboard |> Effect.fromCmd )



--


type Model
    = Initialized
    | Loading User
    | Loaded LoadedModel
    | Error Http.Error


type alias LoadedModel =
    { token : User
    , dashboard : Dashboard
    , orderBy : Maybe OrderBy
    , dialog : Dialog
    }


type OrderBy
    = CreatedAt
    | UpdatedAt


type Dialog
    = DialogHidden


type Msg
    = NoOp
    | GotDashboard (Shared.Response (Maybe Dashboard))
    | ClickedCloseDialog
    | SharedMsg Shared.Msg


update : Shared -> Msg -> Model -> ( Model, Effect Shared.Msg Msg )
update shared msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )

        GotDashboard res ->
            case model of
                Loading token ->
                    case res of
                        Ok Nothing ->
                            ( model, Shared.replaceRoute Route.Register |> Effect.fromShared )

                        Ok (Just dashboard) ->
                            ( Loaded
                                { token = token
                                , dashboard = dashboard
                                , orderBy = Nothing
                                , dialog = DialogHidden
                                }
                            , Effect.none
                            )

                        Err err ->
                            if Shared.isRoleError err then
                                ( model, Shared.replaceRoute Route.Register |> Effect.fromShared )

                            else
                                none model

                Loaded loaded ->
                    case res of
                        Ok Nothing ->
                            ( model, Effect.none )

                        Ok (Just dashboard) ->
                            ( Loaded { loaded | dashboard = dashboard }, Effect.none )

                        Err _ ->
                            none model

                _ ->
                    none model

        ClickedCloseDialog ->
            case model of
                Loaded loaded ->
                    case loaded.dialog of
                        _ ->
                            ( Loaded { loaded | dialog = DialogHidden }
                            , Dialog.closeDialog "dialog" |> Effect.fromCmd
                            )

                _ ->
                    none model

        SharedMsg sharedMsg ->
            ( model, sharedMsg |> Effect.fromShared )


none model =
    ( model, Effect.none )


onLoaded : Model -> (LoadedModel -> ( Model, Effect Shared.Msg Msg )) -> ( Model, Effect Shared.Msg Msg )
onLoaded model operation =
    case model of
        Loaded loaded ->
            operation loaded

        _ ->
            none model


view : Shared -> Model -> View Msg
view shared model =
    { title = "ホーム"
    , body =
        div []
            [ case model of
                Initialized ->
                    text "Initialized"

                Loading _ ->
                    text "Loading..."

                Error err ->
                    div [ class "flex flex-col h-screen justify-center items-center" ]
                        [ div [ class "rounded bg-primary-100 px-8 py-8 flex flex-col justify-center items-center" ]
                            [ div [ class "sr-only" ] [ text <| Common.errorToString err ]
                            , div [] [ text "再度ログインしてください" ]
                            , div [] [ Ui.Button.link "ログイン" [ Ui.Button.linkSpa "__BACKEND_ENDPOINT__/auth/twitter" ] ]
                            ]
                        ]

                Loaded loaded ->
                    -- ul [ class "space-y-4" ] <| List.map (\s -> li [] [ viewTweet s ]) loaded.tweets
                    Shared.view SharedMsg
                        (Just Route.Home)
                        loaded.token
                        (div [ class "space-y-4" ]
                            [ h2 [] [ text "登録されているスケジュール一覧" ]
                            , div [ class "overflow-x-auto" ]
                                [ div [ class "align-middle inline-block min-w-full" ]
                                    [ div [ class "shadow overflow-hidden" ]
                                        [ table [ class "table-fixed min-w-full divide-y divide-gray-200" ]
                                            [ caption [] [ text "RSSタスク" ]
                                            , thead [ class "bg-gray-100" ]
                                                [ th
                                                    [ class "p-2 text-left text-xs font-medium text-gray-500 uppercase"
                                                    , A.scope "col"
                                                    ]
                                                    [ text "ツイートする時間"
                                                    ]
                                                , th
                                                    [ class "p-2 text-left text-xs font-medium text-gray-500 uppercase"
                                                    , A.scope "col"
                                                    , A.colspan 7
                                                    ]
                                                    [ text "ツイートする曜日"
                                                    ]
                                                , th
                                                    [ class "p-2 text-left text-xs font-medium text-gray-500 uppercase"
                                                    , A.scope "col"
                                                    ]
                                                    [ text "ステータス"
                                                    ]
                                                , th
                                                    [ class "p-2 text-left text-xs font-medium text-gray-500 uppercase"
                                                    , A.scope "col"
                                                    ]
                                                    [ text "選択方法"
                                                    ]
                                                , th
                                                    [ class "p-2 text-left text-xs font-medium text-gray-500 uppercase"
                                                    , A.scope "col"
                                                    ]
                                                    [ text "テンプレート"
                                                    ]
                                                , th [ class "p-2", A.scope "col" ] []
                                                ]

                                            -- , tbody [ class "bg-white divide-y divide-gray-200" ] (List.map viewTask loaded.dashboard.rssTasks)
                                            ]
                                        ]
                                    ]
                                ]

                            -- , div [] <| List.map viewTask loaded.dashboard.tasks
                            , case loaded.dialog of
                                DialogHidden ->
                                    Dialog.hidden "dialog"
                            ]
                        )
            ]
    }
