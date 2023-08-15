module Pages.Register exposing (..)

import Effect exposing (Effect)
import Email
import Form.Decoder as FD
import Form.Decoder.Extra as FD
import Graphql.Operation exposing (RootMutation)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Hasura.Mutation
import Hasura.Object.ConfirmEmailOutput
import Hasura.Object.RegisterEmailOutput
import Html exposing (div, h1, img, text)
import Html.Attributes as A exposing (class)
import InteropDefinitions
import InteropPorts
import Model.User as User exposing (User)
import Route
import Shared exposing (Shared)
import Spa.Page
import State
import Ui.Button
import Ui.TextInput
import View exposing (View)


page : Shared -> Spa.Page.Page () Shared.Msg (View Msg) Model Msg
page shared =
    Spa.Page.element
        { init = init shared
        , update = update shared
        , subscriptions = subscriptions
        , view = view shared
        }


init : Shared -> () -> ( Model, Effect Shared.Msg Msg )
init shared _ =
    case shared.state of
        State.Registered user ->
            case user.email of
                User.Unregistered ->
                    ( Loaded { form = emptyRegistForm, session = user }, Effect.none )

                User.Unconfirmed email ->
                    ( WaitConfirmation { form = emptyConfirmForm, session = user, email = email, error = Nothing }, Effect.none )

                User.Confirmed _ ->
                    ( Initialized, Shared.replaceRoute Route.Home |> Effect.fromShared )

        State.ServerError ->
            ( Unauthorized, Effect.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    InteropPorts.toElm
        |> Sub.map
            (\result ->
                case result of
                    Ok (InteropDefinitions.GotToken state) ->
                        GotToken state

                    _ ->
                        NoOp
            )


type Model
    = Initialized
    | Loaded RegistModel
    | WaitConfirmation ConfirmModel
    | Unauthorized
    | Loading Model


type alias RegistModel =
    { form : RegistForm
    , session : User
    }


type alias RegistForm =
    { email : String
    , submitting : Bool
    }


emptyRegistForm : RegistForm
emptyRegistForm =
    { email = ""
    , submitting = False
    }


type alias RegistInput =
    { email : String
    }


registerEmail : RegistInput -> SelectionSet Email.Email RootMutation
registerEmail input =
    Hasura.Mutation.registerEmail { args = input }
        (SelectionSet.mapOrFail
            (\s ->
                case Email.fromString s of
                    Just email ->
                        Ok email

                    Nothing ->
                        Err "不正なメールアドレスです"
            )
            Hasura.Object.RegisterEmailOutput.email
        )


registFd : FD.Decoder RegistForm FD.FormError RegistInput
registFd =
    FD.top RegistInput
        |> FD.field (FD.lift .email emailFd)


emailFd : FD.Decoder String FD.FormError String
emailFd =
    FD.custom <|
        \s ->
            case Email.fromString s of
                Just email ->
                    Ok (Email.toString email)

                Nothing ->
                    Err [ FD.Custom [ "不正なメールアドレスです" ] ]



--


type alias ConfirmModel =
    { form : ConfirmForm
    , email : Email.Email
    , session : User
    , error : Maybe String
    }


type alias ConfirmForm =
    { code : String }


emptyConfirmForm : ConfirmForm
emptyConfirmForm =
    { code = "" }


type alias ConfrimInput =
    { email : String, code : String }


confirmEmail : ConfrimInput -> SelectionSet Bool RootMutation
confirmEmail input =
    Hasura.Mutation.confirmEmail { args = input } Hasura.Object.ConfirmEmailOutput.result



--


type Msg
    = NoOp
    | GotRegistResponse (Shared.Response Email.Email)
    | FormChanged RegistForm
    | ClickedRegister
    | ConfirmFormChanged ConfirmForm
    | ClickedConfirm
    | GotConfirmResponse (Shared.Response Bool)
    | ClickedLogin
    | ClickedLogout
    | ClickedResend
    | GotToken State.State


update : Shared -> Msg -> Model -> ( Model, Effect Shared.Msg Msg )
update shared msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )

        FormChanged form ->
            case model of
                Loaded loaded ->
                    ( Loaded { loaded | form = form }, Effect.none )

                _ ->
                    ( model, Effect.none )

        ClickedRegister ->
            case model of
                Loaded loaded ->
                    case FD.run registFd loaded.form of
                        Ok input ->
                            ( loaded.form |> (\form -> Loaded { loaded | form = { form | submitting = True } }) |> Loading
                            , Shared.makeMutation loaded.session (registerEmail input) GotRegistResponse |> Effect.fromCmd
                            )

                        Err _ ->
                            ( loaded.form |> (\form -> Loaded { loaded | form = { form | submitting = True } })
                            , Effect.none
                            )

                _ ->
                    ( model, Effect.none )

        GotRegistResponse resp ->
            case model of
                Loading (Loaded model_) ->
                    case resp of
                        Ok email ->
                            ( WaitConfirmation { form = emptyConfirmForm, email = email, session = model_.session, error = Nothing }, Effect.none )

                        Err err ->
                            ( model, Effect.none )

                _ ->
                    ( model, Effect.none )

        ConfirmFormChanged form ->
            case model of
                WaitConfirmation model_ ->
                    ( WaitConfirmation { model_ | form = form }
                    , Effect.none
                    )

                _ ->
                    ( model, Effect.none )

        ClickedConfirm ->
            case model of
                WaitConfirmation model_ ->
                    ( WaitConfirmation { model_ | error = Nothing }
                    , Shared.makeMutation model_.session
                        (confirmEmail { code = model_.form.code, email = Email.toString model_.email })
                        GotConfirmResponse
                        |> Effect.fromCmd
                    )

                _ ->
                    ( model, Effect.none )

        GotConfirmResponse resp ->
            case model of
                WaitConfirmation model_ ->
                    case resp of
                        Ok result ->
                            if result then
                                -- ここでPort経由で新しいJWTトークンを取得して、
                                -- ( model, Shared.replaceRoute Route.Home |> Effect.fromShared )
                                ( model, InteropPorts.fromElm InteropDefinitions.GetToken |> Effect.fromCmd )

                            else
                                ( model, Effect.none )

                        Err err ->
                            Shared.errorToString err
                                |> (\serverError ->
                                        ( WaitConfirmation { model_ | error = Just serverError }, Effect.none )
                                   )

                _ ->
                    ( model, Effect.none )

        ClickedLogin ->
            ( model, Shared.login |> Effect.fromShared )

        ClickedLogout ->
            ( model, Shared.logout |> Effect.fromShared )

        ClickedResend ->
            case model of
                WaitConfirmation model_ ->
                    ( Loaded { form = emptyRegistForm, session = model_.session }, Effect.none )

                _ ->
                    ( model, Effect.none )

        GotToken state ->
            ( model, Shared.UpdateState state |> Effect.fromShared )


view : Shared -> Model -> View Msg
view shared model =
    { title = "Home"
    , body =
        div [ class "flex flex-col h-screen justify-center items-center" ]
            [ div [ class "mb-8" ] [ img [ class "h-6 g-gray-100", A.src "/assets/still_bott_logo.svg" ] [] ]
            , case model of
                Initialized ->
                    text "Initialized"

                Unauthorized ->
                    div [ class "rounded-md bg-white max-w-md px-8 py-8 flex flex-col justify-center items-center" ]
                        [ div [] [ text "再度ログインしてください" ]
                        , div []
                            [ Ui.Button.button "ログイン"
                                [ Ui.Button.onClick ClickedLogin
                                , Ui.Button.primary
                                ]
                            ]
                        ]

                Loaded { form } ->
                    div [ class "rounded bg-white w-full lg:w-1/3 max-w-md px-8 py-8 flex flex-col justify-center items-center" ]
                        [ h1 [ class "text-center font-bold text-xl my-2" ] [ text "メールアドレスの登録" ]
                        , div [ class "w-full" ]
                            [ Ui.TextInput.view "email"
                                [ Ui.TextInput.email (\s -> FormChanged { form | email = s })
                                , Ui.TextInput.hiddenLabel
                                , Ui.TextInput.value form.email
                                , Ui.TextInput.autofocus
                                , Ui.TextInput.errorMessage (FD.errorMessage form.submitting emailFd form.email)
                                , Ui.TextInput.placeholder "youname@example.com"
                                ]
                            ]
                        , div [ class "my-4" ]
                            [ Ui.Button.button "登録"
                                [ Ui.Button.onClick ClickedRegister
                                , Ui.Button.small
                                ]
                            ]
                        ]

                WaitConfirmation { form, email, error } ->
                    div [ class "rounded-md bg-white sm:w-1/3 max-w-md p-4 space-y-2" ]
                        [ h1 [ class "text-center font-bold text-xl my-2" ] [ text "認証コードを入力" ]
                        , div [ class "text-xs text-center" ] [ text (Email.toString email), text "宛に確認コードを送信しました。" ]
                        , div [ class "text-xs text-center" ] [ text "メッセージに記載された6桁の数字を入力してください。" ]
                        , div []
                            [ Ui.TextInput.view "code"
                                [ Ui.TextInput.text (\s -> ConfirmFormChanged { form | code = s })
                                , Ui.TextInput.hiddenLabel
                                , Ui.TextInput.value form.code
                                , Ui.TextInput.autofocus
                                ]
                            ]
                        , case error of
                            Just error_ ->
                                div [ class "text-sm font-bod text-red-500" ] [ text error_ ]

                            Nothing ->
                                div [] []
                        , div [ class "flex space-x-2 my-4" ]
                            [ div [ class "w-full" ]
                                [ Ui.Button.button "ログアウト"
                                    [ Ui.Button.onClick ClickedLogout
                                    , Ui.Button.ghost
                                    , Ui.Button.small
                                    , Ui.Button.fillContainerWidth
                                    ]
                                ]
                            , div [ class "w-full" ]
                                [ Ui.Button.button "送信"
                                    [ Ui.Button.onClick ClickedConfirm
                                    , Ui.Button.primary
                                    , Ui.Button.small
                                    , Ui.Button.fillContainerWidth
                                    ]
                                ]
                            ]
                        , div [ class "text-center" ]
                            [ Ui.Button.button "認証コードの再送信"
                                [ Ui.Button.onClick ClickedResend
                                , Ui.Button.tiny
                                , Ui.Button.transparent
                                ]
                            ]
                        ]

                Loading model_ ->
                    div [] [ text "通信中" ]
            ]
    }



-- viewForm :  Form ->
