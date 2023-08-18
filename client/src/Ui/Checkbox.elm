module Ui.Checkbox exposing (Attribute, IsSelected(..), containerClass, custom, disabled, enabled, hiddenLabel, id, labelClass, onCheck, view, visibleLabel)

import Accessibility.Aria as Aria
import Accessibility.Key as Key
import Accessibility.Role as Role
import Heroicons.Outline as Outline
import Heroicons.Solid as Solid
import Html exposing (Html, div)
import Html.Attributes as A exposing (attribute, class)
import Html.Events as E
import Ui.Error as Error exposing (ErrorState)
import Ui.Utils as Utils


{-| This disables the input
-}
disabled : Attribute msg
disabled =
    Attribute <| \config -> { config | isDisabled = True }


{-| This enables the input, this is the default behavior
-}
enabled : Attribute msg
enabled =
    Attribute <| \config -> { config | isDisabled = False }


{-| Fire a message when toggling the checkbox.
-}
onCheck : (Bool -> msg) -> Attribute msg
onCheck onCheck_ =
    Attribute <| \config -> { config | onCheck = Just onCheck_ }


{-| Adds CSS to the element containing the input.
-}
containerClass : List (Html.Attribute msg) -> Attribute msg
containerClass styles =
    Attribute <| \config -> { config | containerClass = config.containerClass ++ styles }


{-| Adds CSS to the element containing the label text.

Note that these styles don't apply to the literal HTML label element, since it contains the icon SVG as well.

-}
labelClass : List (Html.Attribute msg) -> Attribute msg
labelClass styles =
    Attribute <| \config -> { config | labelClass = config.labelClass ++ styles }


{-| Hides the visible label. (There will still be an invisible label for screen readers.)
-}
hiddenLabel : Attribute msg
hiddenLabel =
    Attribute <| \config -> { config | hideLabel = True }


{-| Shows the visible label. This is the default behavior
-}
visibleLabel : Attribute msg
visibleLabel =
    Attribute <| \config -> { config | hideLabel = False }


{-| Set a custom ID for this checkbox input and label. If you don't set this,
we'll automatically generate one from the label you pass in, but this can
cause problems if you have more than one checkbox input with the same label on
the page. You might also use this helper if you're manually managing focus.
-}
id : String -> Attribute msg
id id_ =
    Attribute <| \config -> { config | id = Just id_ }


{-| Use this helper to add custom attributes.

Do NOT use this helper to add css styles, as they may not be applied the way
you want/expect if underlying styles change.
Instead, please use the `css` helper.

-}
custom : List (Html.Attribute Never) -> Attribute msg
custom attributes =
    Attribute <| \config -> { config | custom = config.custom ++ attributes }


{-| Customizations for the Checkbox.
-}
type Attribute msg
    = Attribute (Config msg -> Config msg)


{-| This is private. The public API only exposes `Attribute`.
-}
type alias Config msg =
    { id : Maybe String
    , hideLabel : Bool
    , onCheck : Maybe (Bool -> msg)
    , isDisabled : Bool
    , custom : List (Html.Attribute Never)
    , containerClass : List (Html.Attribute msg)
    , labelClass : List (Html.Attribute msg)
    }


{-|

    = Selected --  Checked (rendered with a checkmark)
    | NotSelected -- Not Checked (rendered blank)
    | PartiallySelected -- Indeterminate (rendered dash)

-}
type IsSelected
    = Selected
    | NotSelected
    | PartiallySelected


selectedToMaybe : IsSelected -> Maybe Bool
selectedToMaybe selected =
    case selected of
        Selected ->
            Just True

        NotSelected ->
            Just False

        PartiallySelected ->
            Nothing


onCheckMsg : IsSelected -> (Bool -> msg) -> msg
onCheckMsg selected msg =
    selectedToMaybe selected
        |> Maybe.withDefault False
        |> not
        |> msg


emptyConfig : Config msg
emptyConfig =
    { id = Nothing
    , hideLabel = False
    , onCheck = Nothing
    , isDisabled = False
    , custom = []
    , containerClass = []
    , labelClass = []
    }


applyConfig : List (Attribute msg) -> Config msg -> Config msg
applyConfig attributes beginningConfig =
    List.foldl (\(Attribute update) config -> update config)
        beginningConfig
        attributes


view :
    { label : String
    , selected : IsSelected
    }
    -> List (Attribute msg)
    -> Html msg
view { label, selected } attributes =
    let
        config =
            applyConfig attributes emptyConfig

        idValue =
            case config.id of
                Just specificId ->
                    specificId

                Nothing ->
                    "checkboxk-" ++ Utils.generateId label

        config_ =
            { identifier = idValue
            , containerClass = config.containerClass
            , label = label
            , hideLabel = config.hideLabel
            , labelClass = config.labelClass
            , onCheck = config.onCheck
            , selected = selected
            , disabled = config.isDisabled
            , error = Error.noError
            }

        ( icon, disabledIcon ) =
            viewIcon selected config.isDisabled
    in
    checkboxContainer config_
        [ viewCheckbox config_
            (if config.isDisabled then
                ( [], disabledIcon )

             else
                ( [], icon )
            )
        ]


checkboxContainer : { a | identifier : String, containerClass : List (Html.Attribute msg) } -> List (Html msg) -> Html msg
checkboxContainer model =
    Html.span
        ([ class "block"
         , A.id (model.identifier ++ "-container")
         ]
            ++ model.containerClass
        )


viewIcon : IsSelected -> Bool -> ( Html msg, Html msg )
viewIcon selected isDisabled =
    let
        base content =
            Html.span
                (List.concat
                    [ [ class "h-4 w-4 flex items-center justify-center rounded border" ]
                    , if isDisabled then
                        [ class "bg-gray-400 pointer-events-none cursor-not-allowed" ]

                      else
                        []
                    ]
                )
                content
    in
    case selected of
        Selected ->
            ( base [ Outline.check [] ], base [ Outline.check [] ] )

        NotSelected ->
            ( base [], base [] )

        PartiallySelected ->
            ( base [ Outline.minus [] ], base [ Outline.minus [] ] )


viewCheckbox :
    { a
        | identifier : String
        , selected : IsSelected
        , onCheck : Maybe (Bool -> msg)
        , disabled : Bool
        , label : String
        , hideLabel : Bool
        , labelClass : List (Html.Attribute msg)
    }
    ->
        ( List (Html.Attribute msg)
        , Html msg
        )
    -> Html.Html msg
viewCheckbox config ( styles, icon ) =
    let
        attributes =
            List.concat
                [ [ A.id config.identifier
                  , Role.checkBox
                  , Aria.checked (selectedToMaybe config.selected)
                  , class "flex items-center space-x-2"
                  ]
                , if config.disabled then
                    [ Aria.disabled True ]

                  else
                    config.onCheck
                        |> Maybe.map (onCheckMsg config.selected)
                        |> Maybe.map (\msg -> [ E.onClick msg, Key.onKeyDownPreventDefault [ Key.space msg ] ])
                        |> Maybe.withDefault []
                ]
    in
    Html.div attributes [ icon, Html.text config.label ]
