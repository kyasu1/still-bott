module Shared exposing (..)

import Accessibility.Role as Role
import Browser.Navigation as Nav
import Dict
import Graphql.Http exposing (HttpError)
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.SelectionSet exposing (SelectionSet)
import Hasura.Enum.Role_enum exposing (Role_enum(..))
import Hasura.Mutation
import Hasura.Object.BooleanOutput
import Html exposing (Html, a, button, div, img, li, nav, span, text, ul)
import Html.Attributes as A exposing (class)
import Html.Events exposing (onClick)
import InteropPorts
import Json.Decode as JD
import Model.User exposing (User)
import Route exposing (Route)
import State exposing (State(..))


type alias Shared =
    { key : Nav.Key
    , state : State
    }


type Msg
    = PushRoute Route
    | ReplaceRoute Route
    | GotRestartSchedulerResponse (Response Bool)
    | Load String
    | UpdateState State


user : Shared -> Maybe User
user shared =
    State.identity shared.state


init : JD.Value -> Nav.Key -> ( Shared, Cmd Msg )
init flags key =
    case InteropPorts.decodeFlags flags of
        Ok decoded ->
            ( { key = key
              , state = decoded.state
              }
            , case decoded.state of
                Registered user_ ->
                    if user_.role == Model.User.Anonymous then
                        Nav.replaceUrl key (Route.toUrl Route.Register)

                    else
                        Cmd.none

                _ ->
                    Cmd.none
            )

        Err err ->
            ( { key = key
              , state = State.ServerError
              }
            , Cmd.none
            )


restartScheduler : User -> Cmd Msg
restartScheduler session =
    { dummy = True }
        |> (\args ->
                makeMutation session (Hasura.Mutation.restartScheduler { args = args } Hasura.Object.BooleanOutput.result) GotRestartSchedulerResponse
           )


update : Msg -> Shared -> ( Shared, Cmd Msg )
update msg shared =
    case msg of
        PushRoute route ->
            ( shared, Nav.pushUrl shared.key <| Route.toUrl route )

        ReplaceRoute route ->
            ( shared, Nav.replaceUrl shared.key <| Route.toUrl route )

        Load url ->
            ( shared, Nav.load url )

        GotRestartSchedulerResponse resp ->
            ( shared, Cmd.none )

        UpdateState state ->
            ( { shared | state = state }, Nav.replaceUrl shared.key (Route.toUrl Route.Home) )


subscriptions : Shared -> Sub Msg
subscriptions =
    always Sub.none


replaceRoute : Route -> Msg
replaceRoute =
    ReplaceRoute


pushRoute : Route -> Msg
pushRoute =
    PushRoute


load : String -> Msg
load =
    Load


login : Msg
login =
    Load "/auth/twitter"


logout : Msg
logout =
    Load "/auth/logout"



--


view : (Msg -> msg) -> Maybe Route -> User -> Html msg -> Html msg
view tagger current user_ body =
    div
        []
        [ div [ class "px-8 flex py-4 justify-between sticky top-0 bg-gray-900" ]
            [ div [ class "px-4 py-2 bg-gray-100 w-64" ] [ img [ class "h-6 g-gray-100 ", A.src "/assets/still_bott_logo.svg" ] [] ]
            , button
                [ onClick logout
                , class "text-gray-400 hover:text-white hover:bg-gray-800 group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold"
                ]
                [ text "ログアウト" ]
                |> Html.map tagger
            ]
        , div [ class "flex" ]
            [ side current user_
            , div [ class "pl-72 w-full" ]
                [ div [ class "px-8 py-8" ] [ body ]
                ]
            ]
        ]


side : Maybe Route -> User -> Html msg
side current user_ =
    -- div [ class "fixed inset-y-0 z-50 flex w-72 flex-col" ]
    div [ class "fixed flex w-72 flex-col h-full" ]
        [ div [ class "flex grow flex-col gap-y-5 overflow-y-auto bg-gray-900 px-6 ring-1 ring-white/5" ]
            [ div [ class "flex flex-col items-center space-y-2 mt-8" ]
                [ case user_.profileImageUrl of
                    Just url ->
                        img [ A.src url, class "w-16 h-16 rounded-full" ] []

                    Nothing ->
                        text ""
                , div [ class "font-bold text-white" ] [ text user_.name, text " さん" ]
                , div [ class "text-sm text-gray-200" ] [ text "( ID: ", text user_.username, text " )" ]
                ]
            , nav [ class "flex flex-1 flex-col" ]
                [ ul [ Role.list, A.class "flex flex-1 flex-col gap-y-7" ]
                    [ menuLink current Route.Home "ホーム"
                    , menuLink current Route.Message "メッセージ"
                    , menuLink current Route.FixedTimeTask "時報タスク"
                    , menuLink current Route.Tag "タグの管理"
                    , menuLink current Route.Media "画像の管理"
                    , menuLink current Route.RssTask "RSSタスク"
                    , menuLink current Route.Log "ログの管理"

                    -- , menuLink current Route.Home "設定"
                    ]
                ]
            ]
        ]


menuLink : Maybe Route -> Route -> String -> Html msg
menuLink current route label =
    let
        base =
            class "p-2 text-sm leading-6 font-semibold flex"
    in
    li []
        [ if current == Just route then
            span [ base, class "bg-gray-800 text-white font-semi-bold " ] [ text label ]

          else
            a
                [ A.href (Route.toUrl route)
                , base
                , class "text-gray-400 hover:text-white hover:bg-gray-800"
                ]
                [ text label
                ]
        ]


viewLoading : Html msg
viewLoading =
    div [ class "flex flex-col h-screen justify-center items-center" ]
        [ div [ class "mb-8" ] [ img [ class "h-6 g-gray-100", A.src "/assets/still_bott_logo.svg" ] [] ]
        , div [ class "text-center" ] [ text "読込中..." ]
        ]



--


type alias Response a =
    Result (Graphql.Http.Error a) a


endpoint : String
endpoint =
    "__HASURA_ENDPOINT__" ++ "/v1/graphql"


withToken : User -> Graphql.Http.Request decodesTo -> Graphql.Http.Request decodesTo
withToken uesr_ =
    Graphql.Http.withHeader "Authorization" ("Bearer " ++ uesr_.token)


makeQuery : User -> SelectionSet a RootQuery -> (Response a -> msg) -> Cmd msg
makeQuery user_ query msg =
    query
        |> Graphql.Http.queryRequest endpoint
        |> withToken user_
        |> Graphql.Http.send msg


makeMutation : User -> SelectionSet a RootMutation -> (Response a -> msg) -> Cmd msg
makeMutation user_ mutation msg =
    mutation
        |> Graphql.Http.mutationRequest endpoint
        |> withToken user_
        |> Graphql.Http.send msg


errorToString : Graphql.Http.Error a -> String
errorToString error =
    case pageError error of
        HttpError ->
            "ネットワークエラー"

        ServerError error_ ->
            error_.message

        Impossible ->
            "未定義エラー"


type Error
    = HttpError
    | ServerError HasuraError
    | Impossible


type alias HasuraError =
    { message : String
    , code : Maybe String
    }


pageError : Graphql.Http.Error a -> Error
pageError error =
    let
        decodeExtensions : JD.Decoder String
        decodeExtensions =
            JD.field "code" JD.string
    in
    case error of
        Graphql.Http.GraphqlError _ errors ->
            case List.head errors of
                Just head ->
                    Dict.get "extensions" head.details
                        |> Maybe.andThen
                            (\extensions ->
                                case JD.decodeValue decodeExtensions extensions of
                                    Ok code ->
                                        Just code

                                    _ ->
                                        Nothing
                            )
                        |> (\code ->
                                ServerError { message = head.message, code = code }
                           )

                Nothing ->
                    Impossible

        Graphql.Http.HttpError _ ->
            HttpError


isRoleError : Graphql.Http.Error a -> Bool
isRoleError error =
    case error of
        Graphql.Http.GraphqlError _ errors ->
            case List.filter (\e -> e.message == "Your requested role is not in allowed roles") errors |> List.head of
                Just _ ->
                    True

                Nothing ->
                    False

        _ ->
            False
