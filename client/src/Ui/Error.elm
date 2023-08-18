module Ui.Error exposing (ErrorState, getErrorMessage, ifError, noError, setErrorIf, setErrorMessage, view)

import Html exposing (Html, div, text)
import Html.Attributes as A exposing (class)


type ErrorState
    = NoError
    | Error
    | ErrorWithMessage String


noError : ErrorState
noError =
    NoError


setErrorIf : Bool -> { config | error : ErrorState } -> { config | error : ErrorState }
setErrorIf ifError_ config =
    { config
        | error =
            if ifError_ then
                Error

            else
                NoError
    }


setErrorMessage : Maybe String -> { config | error : ErrorState } -> { config | error : ErrorState }
setErrorMessage maybeMessage config =
    { config
        | error =
            case maybeMessage of
                Just message ->
                    ErrorWithMessage message

                Nothing ->
                    NoError
    }


ifError : ErrorState -> Bool
ifError v =
    case v of
        NoError ->
            False

        Error ->
            True

        ErrorWithMessage _ ->
            True


getErrorMessage : ErrorState -> Maybe String
getErrorMessage v =
    case v of
        NoError ->
            Nothing

        Error ->
            Nothing

        ErrorWithMessage message ->
            Just message


view : String -> { config | error : ErrorState } -> List (Html msg)
view idValue config =
    if ifError config.error then
        let
            maybeError =
                getErrorMessage config.error
        in
        case maybeError of
            Just errorMessage ->
                [ renderErrorMessage idValue errorMessage ]

            Nothing ->
                []

    else
        []



-- apply :
--     { ifError : String -> a }
--     -> { config | error : ErrorState }
--     -> List a
-- apply { ifError, ifGuidance } config =
--     let
--         maybeError =
--             getErrorMessage config.error
--     in
--     case ( maybeError, config.guidance ) of
--         ( Just errorMessage, Just guidanceMessage ) ->
--             if errorMessage /= guidanceMessage then
--                 [ ifError errorMessage
--                 , ifGuidance guidanceMessage
--                 ]
--             else
--                 [ ifError errorMessage ]
--         ( Just errorMessage, Nothing ) ->
--             [ ifError errorMessage ]
--         ( Nothing, Just guidanceMessage ) ->
--             [ ifGuidance guidanceMessage ]
--         ( Nothing, Nothing ) ->
--             []


renderErrorMessage : String -> String -> Html msg
renderErrorMessage idValue m =
    div
        [ A.id (errorId idValue)
        , class "mt-2 text-sm text-red-600"
        ]
        [ text m ]


errorId : String -> String
errorId idValue =
    idValue ++ "_error-message"



-- Message.view
--     [ Message.tiny
--     , Message.error
--     , Message.plaintext m
--     , Message.alertRole
--     , Message.id (errorId idValue)
--     , Message.custom [ Live.polite ]
--     ]
