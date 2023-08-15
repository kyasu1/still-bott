module Pages.Media exposing (..)

import Dialog
import Effect exposing (Effect)
import Graphql.Http
import Graphql.Operation exposing (RootMutation)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Hasura.InputObject
import Hasura.Mutation
import Heroicons.Outline as Outline
import Html exposing (Html, div, img, input, span, table, tbody, td, text, th, thead, tr)
import Html.Attributes as A exposing (class, src)
import Html.Events as E
import Html.Events.Extra as E
import LocalTime
import Model.Dashboard as Dashboard exposing (Dashboard)
import Model.Media as Media exposing (Media, MediaId)
import Model.User as User exposing (User, UserId)
import Pages.Register exposing (Model(..), Msg(..))
import Process
import Route
import Shared exposing (Shared)
import Spa.Page
import Svg.Attributes as SA
import Task
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
    | LoadError (Graphql.Http.Error (Maybe Dashboard))


type alias LoadedModel =
    { token : User
    , dashboard : Dashboard
    , dialog : Dialog
    }


type Dialog
    = DialogHidden
    | DialogMediaEditor (Maybe MediaId) Form
    | DialogLoading Dialog
    | DialogDeleting Dialog
    | DialogError Dialog String
    | DialogConfirm MediaId


type alias Form =
    { name : String
    , description : String
    }


emptyForm : Form
emptyForm =
    { name = ""
    , description = ""
    }


type alias MediaInput =
    { userId : UserId
    , name : String
    , description : Maybe String
    }



-- saveMedia : MediaInput -> SelectionSet (Maybe Media) RootMutation
-- saveMedia input =
--     Hasura.Mutation.insert_tag_one identity
--         { object =
--             Hasura.InputObject.buildMedia_insert_input
--                 (\args ->
--                     { args
--                         | user_id = Present <| User.userIdToString input.userId
--                         , name = Present input.name
--                         , description =
--                             case input.description of
--                                 Just description ->
--                                     Present description
--                                 Nothing ->
--                                     Absent
--                     }
--                 )
--         }
--         Media.selection
-- updateMedia : MediaId -> MediaInput -> SelectionSet (Maybe Media) RootMutation
-- updateMedia tagId input =
--     Hasura.Mutation.update_tag_by_pk
--         (\args ->
--             { args
--                 | set_ =
--                     Present <|
--                         Hasura.InputObject.buildMedia_set_input
--                             (\args1 ->
--                                 { args1
--                                     | user_id = Present <| User.userIdToString input.userId
--                                     , name = Present input.name
--                                     , description =
--                                         case input.description of
--                                             Just description ->
--                                                 Present description
--                                             Nothing ->
--                                                 Absent
--                                 }
--                             )
--             }
--         )
--         { pk_columns = { id = Media.unwrapId tagId } }
--         Media.selection
-- deleteMedia : MediaId -> SelectionSet (Maybe Media) RootMutation
-- deleteMedia tagId =
--     Hasura.Mutation.delete_tag_by_pk { id = Media.unwrapId tagId } Media.selection


type Msg
    = NoOp
    | ClickedLoadDashboard
    | ClickedDeleteMedia Media
    | GotDashboard (Shared.Response (Maybe Dashboard))
    | ClickedCloseDialog
    | ClickedExecuteDelete MediaId
    | SharedMsg Shared.Msg
    | GotMediaDeleted (Shared.Response MediaId)


update : Shared -> Msg -> Model -> ( Model, Effect Shared.Msg Msg )
update shared msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )

        ClickedLoadDashboard ->
            ( model, Effect.none )

        ClickedDeleteMedia task ->
            onLoaded model
                (\loaded ->
                    case loaded.dialog of
                        DialogHidden ->
                            ( Loaded { loaded | dialog = DialogConfirm task.id }
                            , Dialog.openDialog "dialog" |> Effect.fromCmd
                            )

                        _ ->
                            none model
                )

        ClickedExecuteDelete mediaId ->
            onLoaded model
                (\loaded ->
                    case loaded.dialog of
                        DialogConfirm d ->
                            ( Loaded { loaded | dialog = DialogDeleting (DialogConfirm d) }
                            , Shared.makeMutation loaded.token (Media.deleteMedia mediaId) GotMediaDeleted |> Effect.fromCmd
                            )

                        _ ->
                            none model
                )

        GotMediaDeleted res ->
            onLoaded model
                (\loaded ->
                    case loaded.dialog of
                        DialogDeleting dialog ->
                            case res of
                                Ok mediaId ->
                                    ( Loaded { loaded | dialog = DialogHidden, dashboard = Dashboard.deleteMedia mediaId loaded.dashboard }
                                    , Dialog.closeDialog "dialog" |> Effect.fromCmd
                                    )

                                Err err ->
                                    ( Loaded { loaded | dialog = dialog }, Effect.none )

                        _ ->
                            none model
                )

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
                                , dialog = DialogHidden
                                }
                            , Effect.none
                            )

                        Err err ->
                            ( LoadError err, Effect.none )

                _ ->
                    none model

        ClickedCloseDialog ->
            case model of
                Loaded loaded ->
                    case loaded.dialog of
                        DialogError dialog _ ->
                            ( Loaded { loaded | dialog = dialog }
                            , Effect.none
                            )

                        _ ->
                            ( Loaded { loaded | dialog = DialogHidden }
                            , Dialog.closeDialog "dialog" |> Effect.fromCmd
                            )

                _ ->
                    none model

        SharedMsg sharedMsg ->
            ( model, sharedMsg |> Effect.fromShared )


none : a -> ( a, Effect sharedMsg msg )
none model =
    ( model, Effect.none )


onLoaded : Model -> (LoadedModel -> ( Model, Effect Shared.Msg Msg )) -> ( Model, Effect Shared.Msg Msg )
onLoaded model operation =
    case model of
        Loaded loaded ->
            operation loaded

        _ ->
            none model


updateMedias : Media -> List Media -> List Media
updateMedias updated list =
    if List.map .id list |> List.member updated.id then
        List.map
            (\item ->
                if item.id == updated.id then
                    updated

                else
                    item
            )
            list

    else
        updated :: list


view : Shared -> Model -> View Msg
view shared model =
    { title = "メディア"
    , body =
        div []
            [ case model of
                Initialized ->
                    text "Initialized"

                Loading _ ->
                    text "Loading..."

                LoadError err ->
                    div [ class "flex flex-col h-screen justify-center items-center" ]
                        [ div [ class "rounded bg-primary-100 px-8 py-8 flex flex-col justify-center items-center" ]
                            [ div [ class "sr-only" ] [ text <| Shared.errorToString err ]
                            , div [] [ text "読み込みエラー" ]
                            , div []
                                [ Ui.Button.button "再読み込み" [ Ui.Button.onClick ClickedLoadDashboard ]
                                ]
                            ]
                        ]

                Loaded loaded ->
                    Shared.view SharedMsg (Just Route.FixedTimeTask) loaded.token <|
                        div [ class "space-y-4" ]
                            [ div [ class "grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 bg-white gap-x-6 gap-y-10" ] (List.map viewMedia loaded.dashboard.medias)

                            -- , div [] <| List.map viewMedia loaded.dashboard.tasks
                            , case loaded.dialog of
                                DialogHidden ->
                                    Dialog.hidden "dialog"

                                DialogLoading _ ->
                                    Dialog.loading "dialog"

                                DialogDeleting _ ->
                                    Dialog.loading "deleting"

                                DialogError _ msg ->
                                    Dialog.error { message = msg, ok = ClickedCloseDialog }

                                DialogConfirm mediaId ->
                                    Dialog.confirm { message = "削除してよろしいですか？", ok = ClickedExecuteDelete mediaId, cancel = ClickedCloseDialog }

                                DialogMediaEditor _ form ->
                                    Dialog.modal
                                        [ div [] []
                                        ]
                            ]
            ]
    }


viewMedia : Media -> Html Msg
viewMedia media =
    div [ class "hover:bg-gray-100" ]
        [ div [ class "aspect-square w-full overflow-hidden bg-gray-200 rounded-md" ]
            [ img [ class "w-full h-full object-contain object-center", src media.thumbnail ] []
            ]
        , div [ class "p-2 flex space-x-2" ]
            [ Ui.Button.button "削除"
                [ Ui.Button.onClick (ClickedDeleteMedia media)
                , Ui.Button.small
                , Ui.Button.fillContainerWidth
                , Ui.Button.error
                ]
            ]
        ]
