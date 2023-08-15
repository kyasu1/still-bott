module Pages.RssTask exposing (..)

-- import Ui

import Dialog
import Effect exposing (Effect)
import Graphql.Http
import Graphql.Operation exposing (RootMutation)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Hasura.InputObject
import Hasura.Mutation
import Heroicons.Outline as Outline
import Html exposing (Html, div, input, span, table, tbody, td, text, th, thead, tr)
import Html.Attributes as A exposing (class)
import Html.Events as E
import Html.Events.Extra as E
import LocalTime
import Model.Dashboard as Dashboard exposing (Dashboard)
import Model.TaskRss as Task exposing (Task, TaskId)
import Model.User as User exposing (User, UserId)
import Pages.Register exposing (Model(..), Msg(..))
import Route
import Shared exposing (Shared)
import Spa.Page
import Svg.Attributes as SA
import Task
import Ui.Button
import Ui.RadioButton
import Url
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
    | DialogTaskEditor (Maybe TaskId) Form
    | DialogLoading Dialog
    | DialogError Dialog String
    | DialogConfirm TaskId


type alias Form =
    { tweetAt : String
    , sun : Bool
    , mon : Bool
    , tue : Bool
    , wed : Bool
    , thu : Bool
    , fri : Bool
    , sat : Bool
    , random : Bool
    , enabled : Bool
    , url : String
    , template : String
    }


emptyForm : Form
emptyForm =
    { tweetAt = ""
    , sun = False
    , mon = False
    , tue = False
    , wed = False
    , thu = False
    , fri = False
    , sat = False
    , random = False
    , enabled = False
    , url = ""
    , template = ""
    }


type alias TaskInput =
    { userId : UserId
    , tweetAt : LocalTime.LocalTime
    , sun : Bool
    , mon : Bool
    , tue : Bool
    , wed : Bool
    , thu : Bool
    , fri : Bool
    , sat : Bool
    , random : Bool
    , enabled : Bool
    , url : String
    , template : Maybe String
    }


saveTask : TaskInput -> SelectionSet (Maybe Task) RootMutation
saveTask input =
    Hasura.Mutation.insert_task_rss_one identity
        { object =
            Hasura.InputObject.buildTask_rss_insert_input
                (\args ->
                    { args
                        | user_id = Present <| User.userIdToString input.userId
                        , tweet_at = Present input.tweetAt
                        , sun = Present input.sun
                        , mon = Present input.mon
                        , tue = Present input.tue
                        , wed = Present input.wed
                        , thu = Present input.thu
                        , fri = Present input.fri
                        , sat = Present input.sat
                        , enabled = Present input.enabled
                        , random = Present input.random
                        , url = Present input.url
                        , template =
                            case input.template of
                                Just template ->
                                    Present template

                                Nothing ->
                                    Absent
                    }
                )
        }
        Task.selection


updateTask : TaskId -> TaskInput -> SelectionSet (Maybe Task) RootMutation
updateTask taskId input =
    Hasura.Mutation.update_task_rss_by_pk
        (\args ->
            { args
                | set_ =
                    Present <|
                        Hasura.InputObject.buildTask_rss_set_input
                            (\args1 ->
                                { args1
                                    | tweet_at = Present input.tweetAt
                                    , sun = Present input.sun
                                    , mon = Present input.mon
                                    , tue = Present input.tue
                                    , wed = Present input.wed
                                    , thu = Present input.thu
                                    , fri = Present input.fri
                                    , sat = Present input.sat
                                    , enabled = Present input.enabled
                                    , random = Present input.random
                                    , url = Present input.url
                                    , template =
                                        case input.template of
                                            Just template ->
                                                Present template

                                            Nothing ->
                                                Absent
                                }
                            )
            }
        )
        { pk_columns = { id = Task.unwrapId taskId } }
        Task.selection


deleteTask : TaskId -> SelectionSet (Maybe Task) RootMutation
deleteTask taskId =
    Hasura.Mutation.delete_task_rss_by_pk { id = Task.unwrapId taskId } Task.selection


type Msg
    = NoOp
    | ClickedLoadDashboard
    | ClickedNewTask
    | ClickedEditTask Task
    | ClickedDeleteTask Task
    | ClickedSaveTask
    | GotSaveTaskResponse (Shared.Response (Maybe Task))
    | ChangedForm Form
    | GotDashboard (Shared.Response (Maybe Dashboard))
    | ClickedCloseDialog
    | ClickedExecuteDelete TaskId
    | ClickedRestartScheduler
    | SharedMsg Shared.Msg


update : Shared -> Msg -> Model -> ( Model, Effect Shared.Msg Msg )
update shared msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )

        ClickedLoadDashboard ->
            ( model, Effect.none )

        ClickedNewTask ->
            case model of
                Loaded loaded ->
                    ( Loaded { loaded | dialog = DialogTaskEditor Nothing emptyForm }
                    , Dialog.openDialog "dialog" |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        ClickedEditTask task ->
            case model of
                Loaded loaded ->
                    case loaded.dialog of
                        DialogHidden ->
                            let
                                form : Form
                                form =
                                    { tweetAt = LocalTime.toString task.tweetAt
                                    , sun = task.sun
                                    , mon = task.mon
                                    , tue = task.tue
                                    , wed = task.wed
                                    , thu = task.thu
                                    , fri = task.fri
                                    , sat = task.sat
                                    , random = task.random
                                    , enabled = task.enabled
                                    , url = Url.toString task.url
                                    , template = task.tempalte |> Maybe.withDefault ""
                                    }
                            in
                            ( Loaded { loaded | dialog = DialogTaskEditor (Just task.id) form }
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
                        DialogTaskEditor maybeMessageId _ ->
                            ( Loaded { loaded | dialog = DialogTaskEditor maybeMessageId form }, Effect.none )

                        _ ->
                            none model

                _ ->
                    none model

        ClickedSaveTask ->
            case model of
                Loaded loaded ->
                    case loaded.dialog of
                        DialogTaskEditor maybeTaskId form ->
                            case LocalTime.parser form.tweetAt of
                                Ok tweetAt ->
                                    let
                                        input : TaskInput
                                        input =
                                            { userId = loaded.dashboard.userId
                                            , tweetAt = tweetAt
                                            , sun = form.sun
                                            , mon = form.mon
                                            , tue = form.tue
                                            , wed = form.wed
                                            , thu = form.thu
                                            , fri = form.fri
                                            , sat = form.sat
                                            , random = form.random
                                            , enabled = form.enabled
                                            , url = form.url
                                            , template =
                                                if String.isEmpty form.template then
                                                    Nothing

                                                else
                                                    Just form.template
                                            }
                                    in
                                    case maybeTaskId of
                                        Just taskId ->
                                            ( Loaded { loaded | dialog = DialogLoading (DialogTaskEditor maybeTaskId form) }
                                            , Shared.makeMutation loaded.token (updateTask taskId input) GotSaveTaskResponse |> Effect.fromCmd
                                            )

                                        Nothing ->
                                            ( Loaded { loaded | dialog = DialogLoading (DialogTaskEditor maybeTaskId form) }
                                            , Shared.makeMutation loaded.token (saveTask input) GotSaveTaskResponse |> Effect.fromCmd
                                            )

                                Err _ ->
                                    ( Loaded { loaded | dialog = DialogError loaded.dialog "バリデーションエラー" }
                                    , Effect.none
                                    )

                        _ ->
                            none model

                _ ->
                    none model

        GotSaveTaskResponse resp ->
            onLoaded model
                (\loaded ->
                    case loaded.dialog of
                        DialogLoading dialog ->
                            case resp of
                                Ok (Just task) ->
                                    ( Loaded
                                        { loaded
                                            | dialog = DialogHidden
                                            , dashboard = (\d -> { d | rssTasks = updateTasks task d.rssTasks }) loaded.dashboard
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

        ClickedDeleteTask task ->
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
                            , Shared.makeMutation loaded.token (deleteTask taskId) GotSaveTaskResponse |> Effect.fromCmd
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

        ClickedRestartScheduler ->
            onLoaded model
                (\loaded ->
                    ( model, Shared.restartScheduler loaded.token |> Effect.fromSharedCmd )
                )

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


updateTasks : Task -> List Task -> List Task
updateTasks updated list =
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
                    Shared.view SharedMsg (Just Route.RssTask) loaded.token <|
                        div [ class "space-y-4" ]
                            [ div [ class "flex justify-between" ]
                                [ div [ class "flex space-x-2" ]
                                    [ Ui.Button.button "スケジューラ再起動" [ Ui.Button.onClick ClickedRestartScheduler ]
                                    , Ui.Button.button "新規タスク" [ Ui.Button.onClick ClickedNewTask ]
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
                                                , tbody [ class "bg-white divide-y divide-gray-200" ] (List.map viewTask loaded.dashboard.rssTasks)
                                                ]
                                            ]
                                        ]
                                    ]
                                ]

                            -- , div [] <| List.map viewTask loaded.dashboard.tasks
                            , case loaded.dialog of
                                DialogHidden ->
                                    Dialog.hidden "dialog"

                                DialogLoading _ ->
                                    Dialog.loading "dialog"

                                DialogError _ msg ->
                                    Dialog.error { message = msg, ok = ClickedCloseDialog }

                                DialogConfirm messageId ->
                                    Dialog.confirm { message = "削除してよろしいですか？", ok = ClickedExecuteDelete messageId, cancel = ClickedCloseDialog }

                                DialogTaskEditor _ form ->
                                    Dialog.modal
                                        [ div [] []
                                        , viewTaskForm form
                                        ]
                            ]
            ]
    }


viewTaskForm : Form -> Html Msg
viewTaskForm form =
    div [ class "space-y-2" ]
        [ div [ class "" ]
            [ Html.label [ class "text-sm font-bold text-gray-900" ] [ text "ツイートする時刻" ]
            , div []
                [ Html.input [ A.type_ "time", A.value form.tweetAt, E.onInput (\s -> ChangedForm { form | tweetAt = s }) ]
                    []
                ]
            ]
        , div []
            [ Html.label [ class "text-sm font-bold text-gray-900" ] [ text "ツイートする曜日" ]
            , div [ class "flex" ]
                [ formCheck { value = form.sun, label = "日", id = "form-check-sun", name = "sunday", onClick = ChangedForm { form | sun = not form.sun } }
                , formCheck { value = form.mon, label = "月", id = "form-check-mon", name = "monday", onClick = ChangedForm { form | mon = not form.mon } }
                , formCheck { value = form.tue, label = "火", id = "form-check-tue", name = "tuesday", onClick = ChangedForm { form | tue = not form.tue } }
                , formCheck { value = form.wed, label = "水", id = "form-check-wed", name = "wednesday", onClick = ChangedForm { form | wed = not form.wed } }
                , formCheck { value = form.thu, label = "木", id = "form-check-thu", name = "thursday", onClick = ChangedForm { form | thu = not form.thu } }
                , formCheck { value = form.fri, label = "金", id = "form-check-fri", name = "friday", onClick = ChangedForm { form | fri = not form.fri } }
                , formCheck { value = form.sat, label = "土", id = "form-check-sat", name = "saturday", onClick = ChangedForm { form | sat = not form.sat } }
                ]
            ]
        , div []
            [ Html.label [ class "text-sm font-bold text-gray-900" ] [ text "ステータス" ]
            , div [ class "flex space-x-4" ]
                [ Ui.RadioButton.view
                    { label = "有効"
                    , name = "status"
                    , value = True
                    , valueToString = \_ -> "True"
                    , selectedValue = Just form.enabled
                    }
                    [ Ui.RadioButton.onSelect (\value -> ChangedForm { form | enabled = value }) ]
                , Ui.RadioButton.view
                    { label = "無効"
                    , name = "status"
                    , value = False
                    , valueToString = \_ -> "False"
                    , selectedValue = Just form.enabled
                    }
                    [ Ui.RadioButton.onSelect (\value -> ChangedForm { form | enabled = value }) ]
                ]
            ]
        , div []
            [ Html.label [ class "text-sm font-bold text-gray-900" ] [ text "メッセージのの選び方" ]

            -- , div [] [ Ui.toggle form.random (ChangedForm { form | random = not form.random }) ]
            , Html.fieldset [ class "mt-4" ]
                [ Html.legend [ class "sr-only" ] [ text "メッセージの選び方" ]
                , div [ class "flex items-center space-x-4" ]
                    [ div [ class "flex items-center" ]
                        [ Html.input
                            [ A.id "radio-newest-message"
                            , A.type_ "radio"
                            , A.checked (not form.random)
                            , class "h-4 w-4 border-gray-300 text-indigo-600 focus:ring-indigo-600"
                            , E.onClick (ChangedForm { form | random = not form.random })
                            ]
                            []
                        , Html.label
                            [ A.for "radio-newest-message"
                            , class "ml-3 block text-sm font-medium leading-6 text-gray-900"
                            ]
                            [ text "最新のメッセージ" ]
                        ]
                    , div [ class "flex items-center" ]
                        [ Html.input
                            [ A.id "radio-newest-message"
                            , A.type_ "radio"
                            , A.checked form.random
                            , class "h-4 w-4 border-gray-300 text-indigo-600 focus:ring-indigo-600"
                            , E.onClick (ChangedForm { form | random = not form.random })
                            ]
                            []
                        , Html.label
                            [ A.for "radio-newest-message"
                            , class "ml-3 block text-sm font-medium leading-6 text-gray-900"
                            ]
                            [ text "ランダムに選ぶ" ]
                        ]
                    ]
                ]
            ]
        , div [ class "flex flex-col" ]
            [ Html.label [ class "text-sm font-bold text-gray-900" ] [ text "RSSフィードのURL" ]
            , Html.input [ E.onChange (\s -> ChangedForm { form | url = s }), A.value form.url ] []
            , Html.span []
                [ case Url.fromString form.url of
                    Just url ->
                        text (Url.toString url |> Url.percentDecode |> Maybe.withDefault form.url)

                    Nothing ->
                        text "Invalid URL"
                ]
            ]
        , div [ class "flex flex-col" ]
            [ Html.label [ class "text-sm font-bold text-gray-900" ] [ text "テンプレート" ]
            , Html.textarea
                [ A.rows 10
                , E.onChange (\s -> ChangedForm { form | template = s })
                ]
                [ text form.template ]
            ]
        , div [ class "flex justify-end space-x-2" ]
            [ div [ class "w-40" ]
                [ Ui.Button.button "取消"
                    [ Ui.Button.onClick ClickedCloseDialog
                    , Ui.Button.small
                    , Ui.Button.exactWidth 140
                    , Ui.Button.outline
                    ]
                ]
            , div [ class "w-40" ]
                [ Ui.Button.button "保存"
                    [ Ui.Button.onClick ClickedSaveTask
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


viewTask : Task -> Html Msg
viewTask task =
    tr [ class "hover:bg-gray-100" ]
        [ td [ class "p-2 text-base font-medium text-gray-900" ] [ text (LocalTime.toString task.tweetAt) ]
        , viewCheck task.sun "日"
        , viewCheck task.mon "月"
        , viewCheck task.tue "火"
        , viewCheck task.wed "水"
        , viewCheck task.thu "木"
        , viewCheck task.fri "金"
        , viewCheck task.sat "土"
        , td [ class "p-2 text-base font-medium text-gray-900" ]
            [ if task.enabled then
                div [ class "flex items-center" ]
                    [ div [ class "h-2.5 w-2.5 rounded-full bg-green-400 mr-2" ] []
                    , text "有効"
                    ]

              else
                div [ class "flex items-center" ]
                    [ div [ class "h-2.5 w-2.5 rounded-full bg-red-400 mr-2" ] []
                    , text "無効"
                    ]
            ]
        , td [ class "p-2 text-base font-medium text-gray-900" ]
            [ if task.random then
                div [] [ text "ランダム" ]

              else
                div [] [ text "最新" ]
            ]
        , td [ class "p-2 text-base font-medium text-gray-900" ]
            [ case task.tempalte of
                Just _ ->
                    text "あり"

                Nothing ->
                    text "なし"
            ]
        , td [ class "p-2 flex space-x-2" ]
            [ Ui.Button.button "削除"
                [ Ui.Button.onClick (ClickedDeleteTask task)
                , Ui.Button.tiny
                ]
            , Ui.Button.button "編集"
                [ Ui.Button.onClick (ClickedEditTask task)
                , Ui.Button.tiny
                ]
            ]
        ]


viewCheck : Bool -> String -> Html msg
viewCheck condition label =
    td [ class "w-10" ]
        [ text label
        , span [ class "ml-1" ]
            [ if condition then
                Outline.check [ SA.class "w-4 h-4 font-bold text-green-600" ]

              else
                Outline.xMark [ SA.class "w-4 h-4 font-bold text-red-400" ]
            ]
        ]
