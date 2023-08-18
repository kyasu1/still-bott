module Ui.TextInput exposing
    ( autofocus
    , custom
    , date
    , disabled
    , email
    , errorIf
    , errorMessage
    , hiddenLabel
    , id
    , onBlur
    , onEnter
    , onFocus
    , placeholder
    , search
    , text
    , value
    , view
    , visibleLabel
    )

import Date
import Email
import Heroicons.Outline as Outline
import Html exposing (Attribute, Html, div)
import Html.Attributes as A exposing (attribute, class)
import Html.Events as E
import Keyboard.Event
import Svg exposing (Svg)
import Svg.Attributes as SA
import Ui.AttributesExtra as AttributesExtra
import Ui.Error exposing (ErrorState)
import Ui.Utils


type alias Config =
    { inputClass : List String
    , error : ErrorState
    , readOnly : Bool
    , disabled : Bool
    , loading : Bool
    , hideLabel : Bool
    , placeholder : Maybe String
    , autofocus : Bool
    , id : Maybe String
    , custom : List (Html.Attribute Never)
    , fieldType : Maybe String
    , autocomplete : Maybe String
    }


applyConfig : List (Attribute value msg) -> Config
applyConfig attributes =
    List.foldl (\(Attribute _ update) config -> update config)
        emptyConfig
        attributes


emptyConfig : Config
emptyConfig =
    { inputClass = []
    , error = Ui.Error.noError
    , readOnly = False
    , disabled = False
    , loading = False
    , hideLabel = False
    , placeholder = Nothing
    , autofocus = False
    , id = Nothing
    , custom = []
    , fieldType = Nothing
    , autocomplete = Nothing
    }


type alias EventsAndValues value msg =
    { currentValue : Maybe value
    , toString : Maybe (value -> String)
    , fromString : Maybe (String -> value)
    , onInput : Maybe (String -> msg)
    , onFocus : Maybe msg
    , onBlur : Maybe msg
    , onEnter : Maybe msg
    , leftIcon : Maybe (List (Svg.Attribute msg) -> Svg msg)
    , onClickRightButton : Maybe msg
    , rightButton : Maybe (Svg msg)
    }


emptyEventsAndValues : EventsAndValues value msg
emptyEventsAndValues =
    { currentValue = Nothing
    , toString = Nothing
    , fromString = Nothing
    , onFocus = Nothing
    , onBlur = Nothing
    , onEnter = Nothing
    , onInput = Nothing
    , leftIcon = Nothing
    , onClickRightButton = Nothing
    , rightButton = Nothing
    }


orExisting : (acc -> Maybe a) -> acc -> acc -> Maybe a
orExisting f new previous =
    case f previous of
        Just just ->
            Just just

        Nothing ->
            f new


applyEvents : List (Attribute value msg) -> EventsAndValues value msg
applyEvents =
    List.foldl
        (\(Attribute eventsAndValues _) existing ->
            { currentValue = orExisting .currentValue eventsAndValues existing
            , toString = orExisting .toString eventsAndValues existing
            , fromString = orExisting .fromString eventsAndValues existing
            , onFocus = orExisting .onFocus eventsAndValues existing
            , onBlur = orExisting .onBlur eventsAndValues existing
            , onEnter = orExisting .onEnter eventsAndValues existing
            , onInput = orExisting .onInput eventsAndValues existing
            , leftIcon = orExisting .leftIcon eventsAndValues existing
            , onClickRightButton = orExisting .onClickRightButton eventsAndValues existing
            , rightButton = orExisting .rightButton eventsAndValues existing
            }
        )
        emptyEventsAndValues


text : (String -> msg) -> Attribute String msg
text onInput_ =
    Attribute
        { emptyEventsAndValues
            | toString = Just identity
            , fromString = Just identity
            , onInput = Just (identity >> onInput_)
        }
        (\config ->
            { config
                | fieldType = Just "text"
                , autocomplete = Nothing
            }
        )


search : Maybe msg -> (String -> msg) -> Attribute String msg
search onClear onInput_ =
    Attribute
        { emptyEventsAndValues
            | toString = Just identity
            , fromString = Just identity
            , onInput = Just (identity >> onInput_)
            , leftIcon = Just Outline.magnifyingGlass
            , onClickRightButton = onClear
            , rightButton = Just (Outline.xMark [ SA.class "w-6 h-6" ])
        }
        (\config ->
            { config
                | fieldType = Just "text"
                , autocomplete = Nothing
            }
        )


{-| An input that allows date entry. The date is represented as a String

Format for a date input field is `YYYY-MM-DD`.

-}
date : (Maybe Date.Date -> msg) -> Attribute (Maybe Date.Date) msg
date onInput_ =
    Attribute
        { emptyEventsAndValues
            | toString = Just (Maybe.map Date.toIsoString >> Maybe.withDefault "")
            , fromString = Just (Date.fromIsoString >> Result.toMaybe)
            , onInput = Just (Date.fromIsoString >> Result.toMaybe >> onInput_)
        }
        (\config ->
            { config
                | fieldType = Just "date"

                -- , inputMode = Nothing
                , autocomplete = Nothing
            }
        )


{-| An input that allows email entry. The email is represented as a String

Format for a email input field is `yourname@example.com`.

-}



-- email : (Maybe Email.Email -> msg) -> Attribute (Maybe Email.Email) msg
-- email onInput_ =
--     Attribute
--         { emptyEventsAndValues
--             | toString = Just (Maybe.map Email.toString >> Maybe.withDefault "")
--             , fromString = Just Email.fromString
--             , onInput = Just (Email.fromString >> onInput_)
--         }
--         (\config ->
--             { config
--                 | fieldType = Just "email"
--                 -- , inputMode = Nothing
--                 , autocomplete = Nothing
--             }
--         )


email : (String -> msg) -> Attribute String msg
email onInput_ =
    Attribute
        { emptyEventsAndValues
            | toString = Just identity
            , fromString = Just identity
            , onInput = Just (identity >> onInput_)
        }
        (\config ->
            { config
                | fieldType = Just "email"
                , autocomplete = Nothing
            }
        )


{-| -}
value : value -> Attribute value msg
value value_ =
    Attribute { emptyEventsAndValues | currentValue = Just value_ } identity


{-| -}
placeholder : String -> Attribute value msg
placeholder text_ =
    Attribute emptyEventsAndValues <|
        \config -> { config | placeholder = Just text_ }


{-| This disables the input
-}
disabled : Attribute value msg
disabled =
    Attribute emptyEventsAndValues <|
        \config -> { config | disabled = True }


{-| Sets whether or not the field will be highlighted as having a validation error.
-}
errorIf : Bool -> Attribute value msg
errorIf =
    Attribute emptyEventsAndValues << Ui.Error.setErrorIf


{-| If `Just`, the field will be highlighted as having a validation error,
and the given error message will be shown.
-}
errorMessage : Maybe String -> Attribute value msg
errorMessage =
    Attribute emptyEventsAndValues << Ui.Error.setErrorMessage


{-| Hides the visible label. (There will still be an invisible label for screen readers.)
-}
hiddenLabel : Attribute value msg
hiddenLabel =
    Attribute emptyEventsAndValues <|
        \config -> { config | hideLabel = True }


{-| Default behavior.
-}
visibleLabel : Attribute value msg
visibleLabel =
    Attribute emptyEventsAndValues <|
        \config -> { config | hideLabel = False }


{-| Causes the TextInput to produce the given `msg` when the field is focused.
-}
onFocus : msg -> Attribute value msg
onFocus msg =
    Attribute { emptyEventsAndValues | onFocus = Just msg } identity


{-| Causes the TextInput to produce the given `msg` when the field is blurred.
-}
onBlur : msg -> Attribute value msg
onBlur msg =
    Attribute { emptyEventsAndValues | onBlur = Just msg } identity


{-| -}
onEnter : msg -> Attribute value msg
onEnter msg =
    Attribute { emptyEventsAndValues | onEnter = Just msg } identity


{-| Sets the `autofocus` attribute of the resulting HTML input.
-}
autofocus : Attribute value msg
autofocus =
    Attribute emptyEventsAndValues <|
        \config -> { config | autofocus = True }


{-| Set a custom ID for this text input and label. If you don't set this,
we'll automatically generate one from the label you pass in, but this can
cause problems if you have more than one text input with the same label on
the page. Use this to be more specific and avoid issues with duplicate IDs!
-}
id : String -> Attribute value msg
id id_ =
    Attribute emptyEventsAndValues <|
        \config -> { config | id = Just id_ }


{-| Use this helper to add custom attributes.

Do NOT use this helper to add css styles, as they may not be applied the way
you want/expect if underlying styles change.
Instead, please use the `css` helper.

-}
custom : List (Html.Attribute Never) -> Attribute value msg
custom attributes =
    Attribute emptyEventsAndValues <|
        \config -> { config | custom = config.custom ++ attributes }


type Attribute value msg
    = Attribute (EventsAndValues value msg) (Config -> Config)


view : String -> List (Attribute value msg) -> Html msg
view label attributes =
    let
        config =
            applyConfig attributes

        inputId =
            case config.id of
                Just id_ ->
                    id_

                Nothing ->
                    Ui.Utils.generateId label

        disabled_ =
            class ""

        isInError =
            Ui.Error.ifError config.error

        eventsAndValues : EventsAndValues value msg
        eventsAndValues =
            applyEvents attributes

        onEnter_ : msg -> Html.Attribute msg
        onEnter_ msg =
            (\event ->
                case event.key of
                    Just "Enter" ->
                        Just msg

                    _ ->
                        Nothing
            )
                |> Keyboard.Event.considerKeyboardEvent
                |> E.on "keydown"

        stringValue =
            eventsAndValues.currentValue
                |> Maybe.map2 identity eventsAndValues.toString
                |> Maybe.withDefault ""

        ( leftIcon, leftIconInputClass ) =
            case eventsAndValues.leftIcon of
                Just icon ->
                    ( [ icon [ SA.class "w-6 h-6" ] ], class "pl-10 pr-2" )

                Nothing ->
                    ( [], class "px-2" )

        ( rightButton, rightButttonClass ) =
            case eventsAndValues.rightButton of
                Just button ->
                    ( Html.button
                        [ A.type_ "button"
                        , AttributesExtra.maybe E.onClick eventsAndValues.onClickRightButton
                        , class "relative -ml-px inline-flex items-center gap-x-1.5 rounded-r-md px-3 py-2 text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
                        , class "disabled:opacity-50 disabled:pointer-events-none disabled:cursor-not-allowed"
                        , A.disabled (String.isEmpty stringValue)
                        ]
                        [ button ]
                    , class "rounded-none rounded-l-md"
                    )

                Nothing ->
                    ( Html.text "", class "rounded-md" )
    in
    div []
        [ Html.label
            [ A.for inputId
            , class "block text-sm font-semibold leading-6 text-gray-900"
            , if config.hideLabel then
                class "hidden"

              else
                class ""
            ]
            [ Html.text label ]
        , div [ class "mt-1 relative flex flex-grow items-stretch focus-within:z-10" ]
            [ div [ class "pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3" ] leftIcon
            , Html.input
                [ A.id inputId
                , A.class "border py-2 w-full"
                , rightButttonClass
                , leftIconInputClass
                , AttributesExtra.maybe A.placeholder config.placeholder
                , AttributesExtra.maybe E.onInput eventsAndValues.onInput
                , AttributesExtra.maybe onEnter_ eventsAndValues.onEnter
                , AttributesExtra.maybe A.type_ config.fieldType
                , AttributesExtra.includeIf config.disabled (A.disabled True)

                -- , AttributesExtra.maybe A.autocomplete config.autocomplete
                , A.value stringValue
                , A.classList
                    [ ( "ring-2 ring-red-600", isInError )
                    , ( "outline-0 ring-2 focus:ring-2 focus-within:ring-red-600", isInError )
                    ]
                ]
                []
            , rightButton
            ]
        , div [] <| Ui.Error.view inputId config
        ]
