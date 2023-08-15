module Pages.Tag exposing (..)

import Dialog
import Effect exposing (Effect)
import Graphql.Http
import Graphql.Operation exposing (RootMutation)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Hasura.InputObject
import Hasura.Mutation
import Html exposing (Html, div, input, span, table, tbody, td, text, th, thead, tr)
import Html.Attributes as A exposing (class)
import Html.Events as E
import Html.Events.Extra as E
import Model.Dashboard as Dashboard exposing (Dashboard)
import Model.Tag as Tag exposing (Tag, TagId)
import Model.User as User exposing (User, UserId)
import Pages.Register exposing (Model(..), Msg(..))
import Route
import Shared exposing (Shared)
import Spa.Page
import Ui.Button
import Ui.TextInput
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
    | DialogTagEditor (Maybe TagId) Form
    | DialogLoading Dialog
    | DialogError Dialog String
    | DialogConfirm TagId


type alias Form =
    { name : String
    , description : String
    }


emptyForm : Form
emptyForm =
    { name = ""
    , description = ""
    }


type alias TagInput =
    { userId : UserId
    , name : String
    , description : Maybe String
    }


saveTag : TagInput -> SelectionSet (Maybe Tag) RootMutation
saveTag input =
    Hasura.Mutation.insert_tag_one identity
        { object =
            Hasura.InputObject.buildTag_insert_input
                (\args ->
                    { args
                        | user_id = Present <| User.userIdToString input.userId
                        , name = Present input.name
                        , description =
                            case input.description of
                                Just description ->
                                    Present description

                                Nothing ->
                                    Absent
                    }
                )
        }
        Tag.selection


updateTag : TagId -> TagInput -> SelectionSet (Maybe Tag) RootMutation
updateTag tagId input =
    Hasura.Mutation.update_tag_by_pk
        (\args ->
            { args
                | set_ =
                    Present <|
                        Hasura.InputObject.buildTag_set_input
                            (\args1 ->
                                { args1
                                    | name = Present input.name
                                    , description =
                                        case input.description of
                                            Just description ->
                                                Present description

                                            Nothing ->
                                                Absent
                                }
                            )
            }
        )
        { pk_columns = { id = Tag.unwrapId tagId } }
        Tag.selection


deleteTag : TagId -> SelectionSet (Maybe Tag) RootMutation
deleteTag tagId =
    Hasura.Mutation.delete_tag_by_pk { id = Tag.unwrapId tagId } Tag.selection


type Msg
    = NoOp
    | ClickedLoadDashboard
    | ClickedNewTag
    | ClickedEditTag Tag
    | ClickedDeleteTag Tag
    | ClickedSaveTag
    | GotSaveTagResponse (Shared.Response (Maybe Tag))
    | ChangedForm Form
    | GotDashboard (Shared.Response (Maybe Dashboard))
    | ClickedCloseDialog
    | ClickedExecuteDelete TagId
    | SharedMsg Shared.Msg


update : Shared -> Msg -> Model -> ( Model, Effect Shared.Msg Msg )
update shared msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )

        ClickedLoadDashboard ->
            ( model, Effect.none )

        ClickedNewTag ->
            case model of
                Loaded loaded ->
                    ( Loaded { loaded | dialog = DialogTagEditor Nothing emptyForm }
                    , Dialog.openDialog "dialog" |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        ClickedEditTag tag ->
            case model of
                Loaded loaded ->
                    case loaded.dialog of
                        DialogHidden ->
                            let
                                form : Form
                                form =
                                    { name = tag.name
                                    , description = Maybe.withDefault "" tag.description
                                    }
                            in
                            ( Loaded { loaded | dialog = DialogTagEditor (Just tag.id) form }
                            , Dialog.openDialog "dialog" |> Effect.fromCmd
                            )

                        _ ->
                            none model

                _ ->
                    none model

        ChangedForm form ->
            case model of
                Loaded loaded ->
                    case loaded.dialog of
                        DialogTagEditor maybeMessageId _ ->
                            ( Loaded { loaded | dialog = DialogTagEditor maybeMessageId form }, Effect.none )

                        _ ->
                            none model

                _ ->
                    none model

        ClickedSaveTag ->
            case model of
                Loaded loaded ->
                    case loaded.dialog of
                        DialogTagEditor maybeTagId form ->
                            let
                                input : TagInput
                                input =
                                    { userId = loaded.dashboard.userId
                                    , name = form.name
                                    , description =
                                        if String.isEmpty form.description then
                                            Nothing

                                        else
                                            Just form.description
                                    }
                            in
                            case maybeTagId of
                                Just taskId ->
                                    ( Loaded { loaded | dialog = DialogLoading (DialogTagEditor maybeTagId form) }
                                    , Shared.makeMutation loaded.token (updateTag taskId input) GotSaveTagResponse |> Effect.fromCmd
                                    )

                                Nothing ->
                                    ( Loaded { loaded | dialog = DialogLoading (DialogTagEditor maybeTagId form) }
                                    , Shared.makeMutation loaded.token (saveTag input) GotSaveTagResponse |> Effect.fromCmd
                                    )

                        _ ->
                            none model

                _ ->
                    none model

        GotSaveTagResponse resp ->
            onLoaded model
                (\loaded ->
                    case loaded.dialog of
                        DialogLoading dialog ->
                            case resp of
                                Ok (Just tag) ->
                                    ( Loaded
                                        { loaded
                                            | dialog = DialogHidden
                                            , dashboard = (\d -> { d | tags = updateTags tag d.tags }) loaded.dashboard
                                        }
                                    , Dialog.closeDialog "dialog" |> Effect.fromCmd
                                    )

                                Ok Nothing ->
                                    ( Loaded { loaded | dialog = DialogError dialog "タスクが削除されてているため保存できません" }, Effect.none )

                                Err err ->
                                    ( Loaded { loaded | dialog = DialogError dialog <| Shared.errorToString err }, Effect.none )

                        _ ->
                            none model
                )

        ClickedDeleteTag task ->
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

        ClickedExecuteDelete taskId ->
            onLoaded model
                (\loaded ->
                    case loaded.dialog of
                        DialogConfirm _ ->
                            ( Loaded { loaded | dialog = DialogLoading DialogHidden }
                            , Shared.makeMutation loaded.token (deleteTag taskId) GotSaveTagResponse |> Effect.fromCmd
                            )

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


updateTags : Tag -> List Tag -> List Tag
updateTags updated list =
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
    { title = "Home"
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
                    Shared.view SharedMsg (Just Route.Tag) loaded.token <|
                        div [ class "space-y-4" ]
                            [ div [ class "flex justify-between" ]
                                [ div [ class "flex space-x-2" ]
                                    [ Ui.Button.button "タグを追加" [ Ui.Button.onClick ClickedNewTag ]
                                    ]
                                ]
                            , div [ class "flex flex-col" ]
                                [ div [ class "overflow-x-auto" ]
                                    [ div [ class "align-middle inline-block min-w-full" ]
                                        [ div [ class "shadow overflow-hidden" ]
                                            [ table [ class "table-fixed min-w-full divide-y divide-gray-200" ]
                                                [ thead [ class "bg-gray-100" ]
                                                    [ th
                                                        [ class "p-2 text-left text-xs font-medium text-gray-500 uppercase"
                                                        , A.scope "col"
                                                        ]
                                                        [ text "タグの名称"
                                                        ]
                                                    , th
                                                        [ class "p-2 text-left text-xs font-medium text-gray-500 uppercase"
                                                        , A.scope "col"
                                                        , A.colspan 7
                                                        ]
                                                        [ text "タグの説明"
                                                        ]
                                                    , th [ class "p-2", A.scope "col" ] []
                                                    ]
                                                , tbody [ class "bg-white divide-y divide-gray-200" ] (List.map viewTag loaded.dashboard.tags)
                                                ]
                                            ]
                                        ]
                                    ]
                                ]

                            -- , div [] <| List.map viewTag loaded.dashboard.tasks
                            , case loaded.dialog of
                                DialogHidden ->
                                    Dialog.hidden "dialog"

                                DialogLoading _ ->
                                    Dialog.loading "dialog"

                                DialogError _ msg ->
                                    Dialog.error { message = msg, ok = ClickedCloseDialog }

                                DialogConfirm messageId ->
                                    Dialog.confirm { message = "削除してよろしいですか？", ok = ClickedExecuteDelete messageId, cancel = ClickedCloseDialog }

                                DialogTagEditor _ form ->
                                    Dialog.modal
                                        [ div [] []
                                        , viewTagForm { tags = loaded.dashboard.tags } form
                                        ]
                            ]
            ]
    }


viewTagForm : { tags : List Tag } -> Form -> Html Msg
viewTagForm tag form =
    div [ class "space-y-2" ]
        [ div []
            [ Html.label [ class "text-sm font-bold text-gray-900" ] [ text "タグの追加" ]
            , Ui.TextInput.view "名前"
                [ Ui.TextInput.text (\s -> ChangedForm { form | name = s })
                , Ui.TextInput.value form.name
                , Ui.TextInput.id "tag_name"
                ]
            ]
        , div []
            [ Ui.TextInput.view "説明"
                [ Ui.TextInput.text (\s -> ChangedForm { form | description = s })
                , Ui.TextInput.value form.description
                , Ui.TextInput.id "description"
                ]
            ]
        , div [ class "flex justify-end space-x-2" ]
            [ div []
                [ Ui.Button.button "取消"
                    [ Ui.Button.onClick ClickedCloseDialog
                    , Ui.Button.small
                    , Ui.Button.exactWidth 140
                    ]
                ]
            , div []
                [ Ui.Button.button "保存"
                    [ Ui.Button.onClick ClickedSaveTag
                    , Ui.Button.small
                    , Ui.Button.exactWidth 140
                    ]
                ]
            ]
        ]


formCheck : { value : Bool, label : String, id : String, name : String, onClick : msg } -> Html msg
formCheck args =
    td [ class "flex flex-col items-center justify-center w-10" ]
        [ Html.label [ A.for args.id ] [ text args.label ]
        , span [ class "" ]
            [ Html.input
                [ A.id args.id
                , A.name args.name
                , A.checked args.value
                , A.type_ "checkbox"
                , class "h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-600"
                , E.onClick args.onClick
                ]
                []
            ]
        ]


viewTag : Tag -> Html Msg
viewTag tag =
    tr [ class "" ]
        [ td [ class "p-2 text-base font-medium text-gray-900" ] [ text tag.name ]
        , td [ class "p-2 text-base font-medium text-gray-900 whitespace-nowrap" ] [ text (Maybe.withDefault "" tag.description) ]
        , td [ class "p-2 flex space-x-2" ]
            [ Ui.Button.button "削除"
                [ Ui.Button.onClick (ClickedDeleteTag tag)
                , Ui.Button.exactWidth 100
                , Ui.Button.tiny
                ]
            , Ui.Button.button "編集"
                [ Ui.Button.onClick (ClickedEditTag tag)
                , Ui.Button.exactWidth 100
                , Ui.Button.tiny
                ]
            ]
        ]
