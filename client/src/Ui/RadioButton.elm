module Ui.RadioButton exposing
    ( containerClass
    , custom
    , disabled
    , enabled
    , errorIf
    , errorMessage
    , hiddenLabel
    , id
    , labelClass
    , onSelect
    , view
    , visibleLabel
    )

import Accessibility.Aria as Aria
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Ui.Error exposing (ErrorState)
import Ui.Utils


{-| This disables the input
-}
disabled : Attribute value msg
disabled =
    Attribute <| \config -> { config | isDisabled = True }


{-| This enables the input, this is the default behavior
-}
enabled : Attribute value msg
enabled =
    Attribute <| \config -> { config | isDisabled = False }


{-| Sets whether or not the field will be highlighted as having a validation error.
-}
errorIf : Bool -> Attribute value msg
errorIf =
    Attribute << Ui.Error.setErrorIf


{-| If `Just`, the field will be highlighted as having a validation error,
and the given error message will be shown.
-}
errorMessage : Maybe String -> Attribute value msg
errorMessage =
    Attribute << Ui.Error.setErrorMessage


onSelect : (value -> msg) -> Attribute value msg
onSelect onSelect_ =
    Attribute <| \config -> { config | onSelect = Just onSelect_ }


{-| Adds CSS to the element containing the input.
-}
containerClass : List String -> Attribute value msg
containerClass styles =
    Attribute <| \config -> { config | containerClass = config.containerClass ++ styles }


{-| Adds CSS to the element containing the label text.

Note that these styles don't apply to the literal HTML label element, since it contains the icon SVG as well.

-}
labelClass : List String -> Attribute value msg
labelClass styles =
    Attribute <| \config -> { config | labelClass = config.labelClass ++ styles }


{-| Hides the visible label. (There will still be an invisible label for screen readers.)
-}
hiddenLabel : Attribute value msg
hiddenLabel =
    Attribute <| \config -> { config | hideLabel = True }


{-| Shows the visible label. This is the default behavior
-}
visibleLabel : Attribute value msg
visibleLabel =
    Attribute <| \config -> { config | hideLabel = False }


{-| Set a custom ID for this radio input and label. If you don't set this,
we'll automatically generate one from the label you pass in, but this can
cause problems if you have more than one radio input with the same label on
the page. You might also use this helper if you're manually managing focus.
-}
id : String -> Attribute value msg
id id_ =
    Attribute <| \config -> { config | id = Just id_ }


{-| Use this helper to add custom attributes.

Do NOT use this helper to add css styles, as they may not be applied the way
you want/expect if underlying styles change.
Instead, please use the `css` helper.

-}
custom : List (Html.Attribute Never) -> Attribute value msg
custom attributes =
    Attribute <| \config -> { config | custom = config.custom ++ attributes }


{-| Customizations for the RadioButton.
-}
type Attribute value msg
    = Attribute (Config value msg -> Config value msg)


{-| This is private. The public API only exposes `Attribute`.
-}
type alias Config value msg =
    { name : Maybe String
    , id : Maybe String
    , isDisabled : Bool
    , error : ErrorState
    , hideLabel : Bool
    , containerClass : List String
    , labelClass : List String
    , custom : List (Html.Attribute Never)
    , onSelect : Maybe (value -> msg)
    , onLockedMsg : Maybe msg
    , disclosedContent : List (Html msg)
    }


emptyConfig : Config value msg
emptyConfig =
    { name = Nothing
    , id = Nothing
    , isDisabled = False
    , error = Ui.Error.noError
    , hideLabel = False
    , containerClass = []
    , labelClass = []
    , custom = []
    , onSelect = Nothing
    , onLockedMsg = Nothing
    , disclosedContent = []
    }


applyConfig : List (Attribute value msg) -> Config value msg -> Config value msg
applyConfig attributes beginningConfig =
    List.foldl (\(Attribute update) config -> update config)
        beginningConfig
        attributes


view :
    { label : String, name : String, value : value, valueToString : value -> String, selectedValue : Maybe value }
    -> List (Attribute value msg)
    -> Html msg
view { label, name, value, valueToString, selectedValue } attributes =
    let
        config =
            applyConfig attributes emptyConfig

        stringValue =
            valueToString value

        idValue =
            case config.id of
                Just specifiedId ->
                    specifiedId

                Nothing ->
                    Ui.Utils.generateId label

        isChecked =
            selectedValue == Just value

        isInError =
            Ui.Error.ifError config.error
    in
    Html.span [ A.id (idValue ++ "-container") ]
        [ Html.input
            ([ A.type_ "radio"
             , A.id idValue
             , A.name name
             , A.value stringValue
             , A.checked isChecked
             , Aria.disabled config.isDisabled
             , A.class "radio"
             , case config.onSelect of
                Just onSelect_ ->
                    E.onClick (onSelect_ value)

                Nothing ->
                    A.class ""
             ]
                ++ List.map (A.map never) config.custom
            )
            []
        , Html.label
            [ A.for idValue, A.class "ml-2 cursor-pointer" ]
            [ Html.span [] [ Html.text label ]
            ]
        , Html.div [] <| Ui.Error.view idValue config
        ]
