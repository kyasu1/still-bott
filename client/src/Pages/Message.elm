module Pages.Message exposing (page)

import Dialog
import Effect exposing (Effect)
import File exposing (File)
import File.Select
import Form.Decoder as FD
import Form.Decoder.Extra as FD
import Graphql.Operation exposing (RootMutation)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Hasura.InputObject
import Hasura.Mutation
import Heroicons.Outline as Outline
import Html exposing (Html, div, img, text)
import Html.Attributes as A exposing (class)
import Html.Events as E
import Html.Events.Extra as E
import Http
import MessageParser
import Model.Dashboard as Dashboard exposing (Dashboard)
import Model.Media as Media exposing (Media, MediaId)
import Model.Message as Message exposing (Message, MessageId)
import Model.Tag as Tag exposing (Tag, TagId)
import Model.User as User exposing (User, UserId)
import Pages.Register exposing (Model(..), Msg(..))
import Route
import Shared exposing (Shared)
import Spa.Page
import Svg.Attributes as SA
import Time
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


init : User -> () -> ( Model, Effect Shared.Msg Msg )
init user flags =
    ( Loading user
    , Shared.makeQuery user (Dashboard.query user.id) GotDashboard |> Effect.fromCmd
    )



--


type Model
    = Loading User
    | Loaded LoadedModel
    | NotLoaded


type alias LoadedModel =
    { token : User
    , dashboard : Dashboard
    , filterBy : Maybe Tag
    , orderBy : Maybe OrderBy
    , dialog : Dialog
    }


type OrderBy
    = CreatedAt
    | UpdatedAt


type Dialog
    = DialogHidden
    | DialogMessageEditor (Maybe MessageId) Form (Maybe Media) (Maybe Tag)
    | DialogMediaPicker Dialog (Maybe Media)
    | DialogLoading Dialog
    | DialogConfirm MessageId
    | DialogError Error Dialog


type Error
    = FailedSaveMessage
    | FileTooLarge
    | InvalidFileType String
    | FailedUploadImage String


errorToString : Error -> String
errorToString v =
    case v of
        FailedSaveMessage ->
            "メッセージの保存時にエラーが発生しました"

        FileTooLarge ->
            "ファイルのサイズが5MBを超えています"

        InvalidFileType fileType ->
            fileType ++ "は対応していないメディア形式です"

        FailedUploadImage code ->
            "メディアアップロードエラー(code=" ++ code ++ ")"


type alias Form =
    { text : String
    , tweeted : Bool
    , priority : String
    , taskIds : List String
    , submitted : Maybe (List FD.FormError)
    }


emptyForm : Form
emptyForm =
    { text = ""
    , tweeted = False
    , priority = "1"
    , taskIds = []
    , submitted = Nothing
    }


type alias MessageInput =
    { userId : UserId
    , text : String
    , tweeted : Bool
    , mediaId : Maybe MediaId
    , priority : Int
    , tagId : Maybe TagId
    }


fd : UserId -> Maybe Media -> Maybe Tag -> FD.Decoder Form FD.FormError MessageInput
fd userId maybeMedia maybeTag =
    FD.top MessageInput
        |> FD.field (FD.always userId)
        |> FD.field fdText
        |> FD.field (FD.lift .tweeted FD.identity)
        |> FD.field (FD.always (Maybe.map .id maybeMedia))
        |> FD.field (FD.lift .priority (FD.int FD.InvalidInteger))
        |> FD.field (FD.always (Maybe.map .id maybeTag))


fdText : FD.Decoder { a | text : String } FD.FormError String
fdText =
    FD.lift .text FD.identity
        |> FD.andThen
            (\s ->
                let
                    length =
                        MessageParser.length s
                in
                if length >= 280 then
                    FD.fail (FD.TooLong length)

                else if String.length (String.trim s) == 0 then
                    FD.fail FD.NotEmpty

                else
                    FD.always s
            )


saveMessage : MessageInput -> SelectionSet (Maybe Message) RootMutation
saveMessage input =
    Hasura.Mutation.insert_message_one identity
        { object =
            Hasura.InputObject.buildMessage_insert_input
                (\args ->
                    { args
                        | user_id = Present <| User.userIdToString input.userId
                        , text = Present input.text
                        , tweeted = Present input.tweeted
                        , media_id = Media.asArg input.mediaId
                        , priority = Present input.priority
                        , tag_id = Tag.asArg input.tagId
                    }
                )
        }
        Message.selection


updateMessage : MessageId -> MessageInput -> SelectionSet (Maybe Message) RootMutation
updateMessage messageId input =
    Hasura.Mutation.update_message_by_pk
        (\args ->
            { args
                | set_ =
                    Present <|
                        Hasura.InputObject.buildMessage_set_input
                            (\args1 ->
                                { args1
                                    | text = Present input.text
                                    , tweeted = Present input.tweeted
                                    , media_id = Media.asArg input.mediaId
                                    , priority = Present input.priority
                                    , tag_id = Tag.asArg input.tagId
                                }
                            )
            }
        )
        { pk_columns = { id = Message.unwrapId messageId } }
        Message.selection


deleteMessage : MessageId -> SelectionSet (Maybe Message) RootMutation
deleteMessage messageId =
    Hasura.Mutation.delete_message_by_pk { id = Message.unwrapId messageId } Message.selection


type Msg
    = NoOp
    | GotDashboard (Shared.Response (Maybe Dashboard))
    | ClickedNewMessage
    | ClickedEditMessage Message
    | ClickedSaveMessage
    | ClickedDeleteMessage Message
    | GotSaveMessageResponse (Shared.Response (Maybe Message))
    | ChangedForm Form
    | ClickedCloseDialog
    | ClickedOpenMediaPicker
    | ClickedPickMedia Media
    | ClickedUploadFile
    | GotFileUploaded MediaId (Result Http.Error ())
    | GotFileSaved (Shared.Response Media)
    | FileLoaded File
    | ClickedExecuteDelete MessageId
    | ChangedTagSelection TagId
    | ClickedRemoveTag
    | SharedMsg Shared.Msg
    | GotPresignPostUrl File (Shared.Response Media.UploadUrl)
    | ClickedReload


update : Shared -> Msg -> Model -> ( Model, Effect Shared.Msg Msg )
update shared msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )

        ClickedReload ->
            case model of
                Loading user ->
                    ( NotLoaded
                    , Shared.makeQuery user (Dashboard.query user.id) GotDashboard |> Effect.fromCmd
                    )

                _ ->
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
                                , filterBy = Nothing
                                , orderBy = Nothing
                                , dialog = DialogHidden
                                }
                            , Effect.none
                            )

                        Err _ ->
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

        ClickedNewMessage ->
            case model of
                Loaded loaded ->
                    ( Loaded { loaded | dialog = DialogMessageEditor Nothing emptyForm Nothing Nothing }
                    , Dialog.openDialog "dialog" |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        ClickedEditMessage message ->
            case model of
                Loaded loaded ->
                    case loaded.dialog of
                        DialogHidden ->
                            let
                                form : Form
                                form =
                                    { text = message.text
                                    , tweeted = message.tweeted
                                    , priority = String.fromInt message.priority
                                    , taskIds = []
                                    , submitted = Nothing
                                    }
                            in
                            ( Loaded { loaded | dialog = DialogMessageEditor (Just message.id) form message.media message.tag }
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
                        DialogMessageEditor maybeMessageId _ maybeMedia mabyeTag ->
                            ( Loaded { loaded | dialog = DialogMessageEditor maybeMessageId form maybeMedia mabyeTag }, Effect.none )

                        _ ->
                            none model

                _ ->
                    none model

        ClickedSaveMessage ->
            case model of
                Loaded loaded ->
                    case loaded.dialog of
                        DialogMessageEditor maybeMessageId form maybeMedia maybeTag ->
                            case FD.run (fd loaded.dashboard.userId maybeMedia maybeTag) form of
                                Ok input ->
                                    let
                                        updated =
                                            { form | submitted = Just [] }
                                    in
                                    case maybeMessageId of
                                        Just messageId ->
                                            ( Loaded { loaded | dialog = DialogLoading (DialogMessageEditor maybeMessageId updated maybeMedia maybeTag) }
                                            , Shared.makeMutation loaded.token (updateMessage messageId input) GotSaveMessageResponse |> Effect.fromCmd
                                            )

                                        Nothing ->
                                            ( Loaded { loaded | dialog = DialogLoading (DialogMessageEditor maybeMessageId updated maybeMedia maybeTag) }
                                            , Shared.makeMutation loaded.token (saveMessage input) GotSaveMessageResponse |> Effect.fromCmd
                                            )

                                Err errors ->
                                    let
                                        updated =
                                            { form | submitted = Just errors }
                                    in
                                    ( Loaded { loaded | dialog = DialogMessageEditor maybeMessageId updated maybeMedia maybeTag }
                                    , Effect.none
                                    )

                        _ ->
                            none model

                _ ->
                    none model

        GotSaveMessageResponse resp ->
            onLoaded model
                (\loaded ->
                    case loaded.dialog of
                        DialogLoading dialog ->
                            case resp of
                                Ok (Just message) ->
                                    ( Loaded
                                        { loaded
                                            | dialog = DialogHidden
                                            , dashboard = (\d -> { d | messages = updateMessages message d.messages }) loaded.dashboard
                                        }
                                    , Cmd.batch
                                        [ Dialog.closeDialog "dialog"
                                        , Shared.makeQuery loaded.token (Dashboard.query loaded.token.id) GotDashboard
                                        ]
                                        |> Effect.fromCmd
                                    )

                                Ok Nothing ->
                                    ( Loaded { loaded | dialog = dialog }, Effect.none )

                                Err err ->
                                    ( Loaded { loaded | dialog = DialogError FailedSaveMessage dialog }, Effect.none )

                        _ ->
                            none model
                )

        ClickedDeleteMessage message ->
            onLoaded model
                (\loaded ->
                    case loaded.dialog of
                        DialogHidden ->
                            ( Loaded { loaded | dialog = DialogConfirm message.id }
                            , Dialog.openDialog "dialog" |> Effect.fromCmd
                            )

                        _ ->
                            none model
                )

        ClickedExecuteDelete messageId ->
            onLoaded model
                (\loaded ->
                    case loaded.dialog of
                        DialogConfirm _ ->
                            ( Loaded { loaded | dialog = DialogLoading DialogHidden }
                            , Shared.makeMutation loaded.token (deleteMessage messageId) GotSaveMessageResponse |> Effect.fromCmd
                            )

                        _ ->
                            none model
                )

        ClickedCloseDialog ->
            case model of
                Loaded loaded ->
                    case loaded.dialog of
                        DialogMediaPicker dialog _ ->
                            ( Loaded { loaded | dialog = dialog }, Effect.none )

                        DialogError _ dialog ->
                            ( Loaded { loaded | dialog = dialog }, Effect.none )

                        _ ->
                            ( Loaded { loaded | dialog = DialogHidden }
                            , Dialog.closeDialog "dialog" |> Effect.fromCmd
                            )

                _ ->
                    none model

        ClickedPickMedia picked ->
            case model of
                Loaded loaded ->
                    case loaded.dialog of
                        DialogMediaPicker dialog _ ->
                            case dialog of
                                DialogMessageEditor maybeMessageId form _ maybeTag ->
                                    ( Loaded { loaded | dialog = DialogMessageEditor maybeMessageId form (Just picked) maybeTag }, Effect.none )

                                _ ->
                                    none model

                        _ ->
                            none model

                _ ->
                    none model

        ClickedOpenMediaPicker ->
            onLoaded model
                (\loaded ->
                    case loaded.dialog of
                        DialogMessageEditor _ _ maybeMedia _ ->
                            ( Loaded { loaded | dialog = DialogMediaPicker loaded.dialog maybeMedia }, Effect.none )

                        _ ->
                            none model
                )

        ClickedUploadFile ->
            onLoaded model
                (\loaded ->
                    case loaded.dialog of
                        DialogMediaPicker dialog maybeMedia ->
                            ( Loaded { loaded | dialog = DialogMediaPicker dialog maybeMedia }
                            , File.Select.file validMediaTypes FileLoaded |> Effect.fromCmd
                            )

                        _ ->
                            none model
                )

        FileLoaded file ->
            onLoaded model
                (\loaded ->
                    case loaded.dialog of
                        DialogMediaPicker dialog maybeMedia ->
                            if File.size file > 1024 * 1024 * 5 then
                                ( Loaded { loaded | dialog = DialogError FileTooLarge loaded.dialog }, Effect.none )

                            else if not (List.member (File.mime file) validMediaTypes) then
                                ( Loaded { loaded | dialog = DialogError (InvalidFileType (File.mime file)) loaded.dialog }
                                , Effect.none
                                )

                            else
                                ( Loaded { loaded | dialog = DialogMediaPicker dialog maybeMedia }
                                , Shared.makeMutation loaded.token Media.getPresignPostUrl (GotPresignPostUrl file) |> Effect.fromCmd
                                )

                        _ ->
                            none model
                )

        GotPresignPostUrl file resp ->
            onLoaded model
                (\loaded ->
                    case loaded.dialog of
                        DialogMediaPicker _ _ ->
                            case resp of
                                Ok uploadUrl ->
                                    ( model
                                    , Http.request
                                        { method = "PUT"
                                        , headers = []
                                        , url = uploadUrl.url
                                        , body = Http.fileBody file
                                        , expect = Http.expectWhatever (GotFileUploaded uploadUrl.mediaId)
                                        , timeout = Nothing
                                        , tracker = Nothing
                                        }
                                        |> Effect.fromCmd
                                    )

                                Err _ ->
                                    ( Loaded { loaded | dialog = DialogError (FailedUploadImage "presign") loaded.dialog }
                                    , Effect.none
                                    )

                        _ ->
                            ( model, Effect.none )
                )

        GotFileUploaded mediaId resp ->
            onLoaded model
                (\loaded ->
                    case loaded.dialog of
                        DialogMediaPicker _ _ ->
                            case resp of
                                Ok _ ->
                                    ( model
                                    , Shared.makeMutation loaded.token (Media.saveMedia mediaId) GotFileSaved |> Effect.fromCmd
                                    )

                                Err err ->
                                    ( Loaded { loaded | dialog = DialogError (FailedUploadImage "minio") loaded.dialog }
                                    , Effect.none
                                    )

                        _ ->
                            none model
                )

        GotFileSaved resp ->
            onLoaded model
                (\loaded ->
                    case loaded.dialog of
                        DialogMediaPicker dialog _ ->
                            case resp of
                                Ok media ->
                                    ( Loaded
                                        { loaded
                                            | dialog = DialogMediaPicker dialog (Just media)
                                            , dashboard = (\d -> { d | medias = media :: d.medias }) loaded.dashboard
                                        }
                                    , Effect.none
                                    )

                                Err err ->
                                    ( Loaded { loaded | dialog = DialogError (FailedUploadImage "save") loaded.dialog }
                                    , Effect.none
                                    )

                        _ ->
                            none model
                )

        ChangedTagSelection tagId ->
            onLoaded model
                (\loaded ->
                    case loaded.dialog of
                        DialogMessageEditor maybeMessageId form maybeMedia _ ->
                            ( Loaded { loaded | dialog = DialogMessageEditor maybeMessageId form maybeMedia (List.filter (\tag -> tag.id == tagId) loaded.dashboard.tags |> List.head) }
                            , Effect.none
                            )

                        _ ->
                            none model
                )

        ClickedRemoveTag ->
            onLoaded model
                (\loaded ->
                    case loaded.dialog of
                        DialogMessageEditor maybeMessageId form maybeMedia _ ->
                            ( Loaded { loaded | dialog = DialogMessageEditor maybeMessageId form maybeMedia Nothing }
                            , Effect.none
                            )

                        _ ->
                            none model
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


updateMessages : Message -> List Message -> List Message
updateMessages current list =
    if List.map .id list |> List.member current.id then
        List.filter (\item -> item.id /= current.id) list

    else
        current :: list


view : Shared -> Model -> View Msg
view shared model =
    { title = "メッセージ"
    , body =
        div []
            [ case model of
                Loading _ ->
                    Shared.viewLoading

                NotLoaded ->
                    div [ class "flex flex-col h-screen justify-center items-center" ]
                        [ div [ class "rounded bg-white-100 px-8 py-8 flex flex-col justify-center items-center space-y-4" ]
                            [ div [] [ text "ダッシュボード読込時にエラーが発生しました" ]
                            , div []
                                [ Ui.Button.button "再読み込み"
                                    [ Ui.Button.onClick ClickedReload
                                    , Ui.Button.small
                                    ]
                                ]
                            , div []
                                [ Ui.Button.button "ログアウト"
                                    [ Ui.Button.onClick (SharedMsg Shared.logout)
                                    , Ui.Button.transparent
                                    , Ui.Button.tiny
                                    ]
                                ]
                            ]
                        ]

                Loaded loaded ->
                    -- ul [ class "space-y-4" ] <| List.map (\s -> li [] [ viewTweet s ]) loaded.tweets
                    Shared.view SharedMsg
                        (Just Route.Message)
                        loaded.token
                        (div [ class "space-y-4" ]
                            [ div [ class "flex justify-between" ]
                                [ div []
                                    [ Ui.Button.button "新規メッセージ" [ Ui.Button.onClick ClickedNewMessage ]
                                    ]
                                ]
                            , div []
                                [ div [ class "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-2" ]
                                    (List.map viewTweet (List.sortBy (\message -> Time.posixToMillis message.createdAt) loaded.dashboard.messages |> List.reverse)
                                        ++ [ div
                                                [ class "w-full p-4 rounded border border-gray-300 border-dashed flex items-center justify-center hover:cursor-pointer hover:bg-gray-200 hover:border-gray-400 h-72"
                                                , E.onClick ClickedNewMessage
                                                ]
                                                [ Outline.plus [ SA.class "w-16 h-16" ]
                                                ]
                                           ]
                                    )
                                ]
                            , case loaded.dialog of
                                DialogHidden ->
                                    Dialog.hidden "dialog"

                                DialogLoading _ ->
                                    Dialog.loading "dialog"

                                DialogConfirm messageId ->
                                    Dialog.confirm { message = "削除してよろしいですか？", ok = ClickedExecuteDelete messageId, cancel = ClickedCloseDialog }

                                DialogMessageEditor _ form maybeMedia maybeTag ->
                                    Dialog.modal
                                        [ div [] []
                                        , viewForm maybeMedia { maybePicked = maybeTag, tags = loaded.dashboard.tags } form
                                        ]

                                DialogMediaPicker _ maybePicked ->
                                    Dialog.modal
                                        [ viewMedia maybePicked loaded.dashboard.medias
                                        ]

                                DialogError error _ ->
                                    Dialog.error
                                        { message = errorToString error
                                        , ok = ClickedCloseDialog
                                        }
                            ]
                        )
            ]
    }


viewMedia : Maybe Media -> List Media -> Html Msg
viewMedia maybePicked medias =
    div []
        [ div []
            [ text "画像を選択してください" ]
        , div [ class "my-4" ]
            [ if List.isEmpty medias then
                div []
                    [ Html.label
                        [ E.onClick ClickedUploadFile
                        , class "flex items-center justify-center p-8 border border-dashed hover:bg-gray-200 hover:cursor-pointer"
                        ]
                        [ text "画像をアップロード" ]
                    ]

              else
                div []
                    [ div [ class "flex items-center justify-center p-8 border border-dashed" ]
                        [ Html.button [ E.onClick ClickedUploadFile ] [ text "画像をアップロード" ]
                        ]
                    , div [ class "grid grid-cols-4 gap-2" ] <| List.map (viewMediaItem maybePicked) medias
                    ]
            ]
        , div [ class "flex justify-end space-x-4" ]
            [ div []
                [ Ui.Button.button "閉じる"
                    [ Ui.Button.onClick ClickedCloseDialog
                    , Ui.Button.small
                    , Ui.Button.outline
                    , Ui.Button.ghost
                    , Ui.Button.exactWidth 140
                    ]
                ]
            , div []
                [ Ui.Button.button "選択する"
                    [ case maybePicked of
                        Just picked ->
                            Ui.Button.onClick (ClickedPickMedia picked)

                        Nothing ->
                            Ui.Button.enabled
                    , Ui.Button.small
                    , Ui.Button.primary
                    , Ui.Button.exactWidth 140
                    ]
                ]
            ]
        ]


viewMediaItem : Maybe Media -> Media -> Html Msg
viewMediaItem maybePicked media =
    div
        [ if maybePicked == Just media then
            class "border border-red-500"

          else
            E.onClick (ClickedPickMedia media)
        , class "hover:cursor-pointer hover:opacity-60"
        ]
        [ Html.img [ class "object-contain w-48 h-48 border", A.src media.thumbnail ] [] ]


viewTweet : Message -> Html Msg
viewTweet message =
    div [ class "flex flex-col w-full p-2 rounded shadow-sm bg-white over-flow-hidden" ]
        [ div [ class "text-sm p-2" ]
            [ case Maybe.map .name message.tag of
                Just tagName ->
                    text tagName

                Nothing ->
                    text "タグは設定されていません"
            ]
        , div [ class "border p-2 text-xs h-48 whitespace-pre-wrap break-words overflow-y-scroll" ] [ text message.text ]
        , img
            [ class "w-auto h-32 object-contain rounded border border-gray-300 mt-4"
            , case message.media of
                Just media ->
                    A.src media.thumbnail

                Nothing ->
                    A.src ""
            ]
            []
        , div [ class "px-2 py-2 flex justify-between" ]
            [ div []
                [ Ui.Button.button "削除"
                    [ Ui.Button.onClick (ClickedDeleteMessage message)
                    , Ui.Button.small
                    , Ui.Button.exactWidth 100
                    ]
                ]
            , div []
                [ Ui.Button.button "編集"
                    [ Ui.Button.onClick (ClickedEditMessage message)
                    , Ui.Button.small
                    , Ui.Button.exactWidth 100
                    ]
                ]
            ]

        -- , Ui.button Ui.Solid Ui.Primary Ui.Xs { onPress = Just <| ClickedTweetNow message, label = text "すぐにツイートする" }
        ]


viewForm : Maybe Media -> { tags : List Tag, maybePicked : Maybe Tag } -> Form -> Html Msg
viewForm maybeMedia tag form =
    div [ class "space-y-2" ]
        [ div [ class "flex items-center" ]
            [ Tag.tagSelectInput tag.maybePicked tag.tags ChangedTagSelection
            , case tag.maybePicked of
                Just _ ->
                    div [ class "ml-2" ]
                        [ Ui.Button.button "削除"
                            [ Ui.Button.onClick ClickedRemoveTag
                            , Ui.Button.small
                            , Ui.Button.icon Outline.trash
                            , Ui.Button.error
                            , Ui.Button.square
                            ]
                        ]

                Nothing ->
                    text ""
            ]
        , div [ class "mt-2" ]
            [ Html.label [ class "sr-only" ] [ text "message" ]
            , div [ A.autofocus True ]
                [ Html.textarea
                    [ A.rows 10
                    , A.name "message"
                    , A.id "message"
                    , class "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                    , A.placeholder "メッセージ"
                    , E.onInput (\s -> ChangedForm { form | text = s })
                    ]
                    [ text form.text ]
                ]
            ]
        , case maybeMedia of
            Just media ->
                div
                    [ class "rounded flex items-center justify-center border border-gray-200 h-48 "
                    , class "hover:cursor-pointer hover:bg-gray-300 hover:border-gray-400"
                    , E.onClick ClickedOpenMediaPicker
                    ]
                    [ img [ A.src media.thumbnail, class "w-full h-full object-contain object-center" ] [] ]

            Nothing ->
                div
                    [ class "rounded w-full flex items-center justify-center border border-dashed border-gray-200 h-48"
                    , class "hover:cursor-pointer hover:bg-gray-300 hover:border-gray-400"
                    , E.onClick ClickedOpenMediaPicker
                    ]
                    [ Outline.plus [ SA.class "w-16 h-16 text-gray-500" ] ]
        , case form.submitted of
            Just errors ->
                div [] <| List.map (\error -> text (FD.toString error)) errors

            Nothing ->
                text ""
        , MessageParser.length form.text
            |> (\length ->
                    if length >= 260 then
                        div [] [ text "残り", text (String.fromInt (280 - length)), text "文字" ]

                    else
                        text ""
               )
        , div [ class "flex justify-end space-x-2" ]
            [ div []
                [ Ui.Button.button "取消"
                    [ Ui.Button.onClick ClickedCloseDialog
                    , Ui.Button.small
                    , Ui.Button.outline
                    , Ui.Button.ghost
                    , Ui.Button.exactWidth 140
                    ]
                ]
            , div []
                [ Ui.Button.button "メッセージ登録"
                    [ Ui.Button.onClick ClickedSaveMessage
                    , Ui.Button.small
                    , Ui.Button.exactWidth 140
                    ]
                ]
            ]
        ]


validMediaTypes : List String
validMediaTypes =
    [ "image/jpeg", "image/gif", "image/png" ]
