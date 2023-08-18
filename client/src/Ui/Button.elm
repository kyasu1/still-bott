module Ui.Button exposing
    ( boundedWidth
    , button
    , circle
    , custom
    , disabled
    , enabled
    , error
    , exactWidth
    , fillContainerWidth
    , ghost
    , href
    , icon
    , large
    , link
    , linkExternal
    , linkSpa
    , medium
    , onClick
    , outline
    , primary
    , rightIcon
    , secondary
    , small
    , square
    , success
    , tiny
    , transparent
    , unboundedWidth
    , warning
    )

import Html exposing (Html)
import Html.Attributes as A exposing (attribute, class)
import Svg exposing (Svg)
import Svg.Attributes as SA
import Ui.ClickableAttributes as ClickableAttributes exposing (ClickableAttributes)


button : String -> List (Attribute msg) -> Html msg
button name attributes =
    (label name :: attributes)
        |> List.foldl (\(Attribute attribute) b -> attribute b) build
        |> renderButton


link : String -> List (Attribute msg) -> Html msg
link name attributes =
    (label name :: attributes)
        |> List.foldl (\(Attribute attribute) l -> attribute l) build
        |> renderLink


label : String -> Attribute msg
label label_ =
    set (\attributes -> { attributes | label = label_ })


icon : (List (Svg.Attribute msg) -> Svg msg) -> Attribute msg
icon icon_ =
    set (\attributes -> { attributes | icon = Just icon_ })


rightIcon : Svg msg -> Attribute msg
rightIcon icon_ =
    set (\attributes -> { attributes | rightIcon = Just icon_ })


type ButtonOrLink msg
    = ButtonOrLink (ButtonOrLinkAttributes msg)


type alias ButtonOrLinkAttributes msg =
    { clickableAttributes : ClickableAttributes String msg
    , label : String
    , size : ButtonSize
    , shape : Shape
    , style : ColorPalette msg
    , width : ButtonWidth
    , state : ButtonState
    , pressed : Maybe Bool
    , outlined : Bool
    , icon : Maybe (List (Svg.Attribute msg) -> Svg msg)
    , iconStyles : List (Svg.Attribute msg)
    , rightIcon : Maybe (Svg msg)
    , customAttributes : List (Html.Attribute msg)
    }


type ButtonState
    = Enabled
      -- | Loading
    | Success
    | Warning
    | Error
    | Disabled


isDisabled : ButtonState -> Bool
isDisabled v =
    case v of
        Disabled ->
            True

        _ ->
            False


enabled : Attribute msg
enabled =
    set (\attributes -> { attributes | state = Enabled })


success : Attribute msg
success =
    set (\attributes -> { attributes | state = Success })


warning : Attribute msg
warning =
    set (\attributes -> { attributes | state = Warning })


error : Attribute msg
error =
    set (\attributes -> { attributes | state = Error })


disabled : Attribute msg
disabled =
    set (\attributes -> { attributes | state = Disabled })



-- BUTTON WIDTH


type ButtonWidth
    = WidthExact Int
    | WidthUnbounded
    | WidthFillContainer
    | WidthBounded { min : Int, max : Int }


setWidth : ButtonWidth -> Attribute msg
setWidth w =
    set (\attributes -> { attributes | width = w })



-- BUTTON SHAPE


type Shape
    = Normal
    | Square
    | Circle


normal : Attribute msg
normal =
    set (\attributes -> { attributes | shape = Normal })


square : Attribute msg
square =
    set (\attributes -> { attributes | shape = Square })


circle : Attribute msg
circle =
    set (\attributes -> { attributes | shape = Circle })



-- BUTTON SIZING


{-| -}
tiny : Attribute msg
tiny =
    set (\attributes -> { attributes | size = Tiny })


{-| -}
small : Attribute msg
small =
    set (\attributes -> { attributes | size = Small })


{-| -}
medium : Attribute msg
medium =
    set (\attributes -> { attributes | size = Medium })


{-| -}
large : Attribute msg
large =
    set (\attributes -> { attributes | size = Large })


{-| Define a size in `px` for the button's total width.
-}
exactWidth : Int -> Attribute msg
exactWidth inPx =
    setWidth (WidthExact inPx)


{-| -}
unboundedWidth : Attribute msg
unboundedWidth =
    setWidth WidthUnbounded


{-| -}
fillContainerWidth : Attribute msg
fillContainerWidth =
    setWidth WidthFillContainer


{-| Make a button that is at least `min` large, and which will grow with
its content up to `max`. Both bounds are inclusive (`min <= actual value <=
max`.)
-}
boundedWidth : { min : Int, max : Int } -> Attribute msg
boundedWidth bounds =
    setWidth (WidthBounded bounds)


{-| Use this helper to add custom attributes.

Do NOT use this helper to add css styles, as they may not be applied the way
you want/expect if underlying Button styles change.
Instead, please use the `css` helper.

-}
custom : List (Html.Attribute msg) -> Attribute msg
custom attributes =
    set
        (\config ->
            { config
                | customAttributes = List.append config.customAttributes attributes
            }
        )



-- EVENTS


onClick : msg -> Attribute msg
onClick msg =
    set (ClickableAttributes.onClick msg)


{-| -}
href : String -> Attribute msg
href url =
    set (ClickableAttributes.href url)


{-| Use this link for routing within a single page app.

This will make a normal <a> tag, but change the Events.onClick behavior to avoid reloading the page.

See <https://github.com/elm-lang/html/issues/110> for details on this implementation.

-}
linkSpa : String -> Attribute msg
linkSpa url =
    set (ClickableAttributes.linkSpa url)


{-| -}
linkExternal : String -> Attribute msg
linkExternal url =
    set (ClickableAttributes.linkExternal url)



-- BUTTON SIZE


type ButtonSize
    = Tiny
    | Small
    | Medium
    | Large



-- OUTLINE BUTTONS


outline : Attribute msg
outline =
    set (\attributes -> { attributes | outlined = True })



-- COLOR SCHEMS


primary : Attribute msg
primary =
    set (\attributes -> { attributes | style = primaryColors })


secondary : Attribute msg
secondary =
    set (\attributes -> { attributes | style = secondaryColors })


ghost : Attribute msg
ghost =
    set (\attributes -> { attributes | style = ghostColors })


transparent : Attribute msg
transparent =
    set (\attributes -> { attributes | style = transparentColors })


{-| -}
type Attribute msg
    = Attribute (ButtonOrLink msg -> ButtonOrLink msg)



-- INTERNALS


set : (ButtonOrLinkAttributes msg -> ButtonOrLinkAttributes msg) -> Attribute msg
set with =
    Attribute (\(ButtonOrLink config) -> ButtonOrLink (with config))


build : ButtonOrLink msg
build =
    ButtonOrLink
        { clickableAttributes = ClickableAttributes.init
        , label = ""
        , size = Medium
        , shape = Normal
        , style = primaryColors
        , width = WidthUnbounded
        , state = Enabled
        , pressed = Nothing
        , outlined = False
        , icon = Nothing
        , iconStyles = []
        , rightIcon = Nothing
        , customAttributes = []
        }


renderButton : ButtonOrLink msg -> Html msg
renderButton ((ButtonOrLink config) as button_) =
    Html.button
        (List.concat
            [ ClickableAttributes.toButtonAttributes config.clickableAttributes { disabled = isDisabled config.state }
            , buttonStyles config
            ]
        )
        (viewContent button_)


renderLink : ButtonOrLink msg -> Html msg
renderLink ((ButtonOrLink config) as link_) =
    Html.a
        (List.concat
            [ ClickableAttributes.toLinkAttributes
                { routeToString = identity
                , isDisabled = isDisabled config.state
                }
                config.clickableAttributes
            , buttonStyles config
            ]
        )
        (viewContent link_)


viewContent : ButtonOrLink msg -> List (Html msg)
viewContent (ButtonOrLink config) =
    List.filterMap identity
        [ Just (viewLabel config)
        , Maybe.map (viewIcon config.size [ SA.class "ml-2" ]) config.rightIcon
        ]


buttonStyles :
    { config
        | size : ButtonSize
        , width : ButtonWidth
        , style : ColorPalette msg
        , shape : Shape
        , state : ButtonState
        , pressed : Maybe Bool
        , outlined : Bool
        , customAttributes : List (Html.Attribute msg)
    }
    -> List (Html.Attribute msg)
buttonStyles ({ state, customAttributes } as config) =
    List.concat
        [ [ class "btn" ]
        , case config.shape of
            Normal ->
                []

            Square ->
                [ class "btn-square" ]

            Circle ->
                [ class "btn-circle" ]
        , sizeStyle config
        , colorStyle config.style state
        , customAttributes
        , if config.outlined then
            [ class "btn-outline" ]

          else
            []
        ]


viewLabel :
    { config
        | size : ButtonSize
        , icon : Maybe (List (Svg.Attribute msg) -> Svg msg)
        , iconStyles : List (Svg.Attribute msg)
        , label : String
    }
    -> Html msg
viewLabel config =
    let
        styles =
            case config.size of
                Tiny ->
                    SA.class "w-3 h-3"

                Small ->
                    SA.class "w-4 h-4"

                Medium ->
                    SA.class "w-6 h-6"

                Large ->
                    SA.class "w-8 h-8"
    in
    case config.icon of
        Nothing ->
            Html.text config.label

        Just icon_ ->
            icon_ (config.iconStyles ++ [ styles ])


viewIcon : ButtonSize -> List (Svg.Attribute msg) -> Svg msg -> Html msg
viewIcon size iconStyles svg =
    Html.span (iconSize size ++ iconStyles) [ svg ]


iconSize : ButtonSize -> List (Svg.Attribute msg)
iconSize size =
    case size of
        Small ->
            [ SA.width "10px", SA.height "10px" ]

        _ ->
            []



-- COLORS


colorStyle : ColorPalette msg -> ButtonState -> List (Html.Attribute msg)
colorStyle color state =
    case state of
        Enabled ->
            applyColorStyle color

        Disabled ->
            applyColorStyle color

        Success ->
            applyColorStyle successColors

        Warning ->
            applyColorStyle warningColors

        Error ->
            applyColorStyle errorColors


type alias ColorPalette msg =
    Html.Attribute msg


primaryColors : ColorPalette msg
primaryColors =
    class "btn-primary"


secondaryColors : ColorPalette msg
secondaryColors =
    class "btn-secondary"


successColors : ColorPalette msg
successColors =
    class "btn-success"


warningColors : ColorPalette msg
warningColors =
    class "btn-warning"


errorColors : ColorPalette msg
errorColors =
    class "btn-error"


ghostColors : ColorPalette msg
ghostColors =
    class "btn-ghost"


transparentColors : ColorPalette msg
transparentColors =
    class "btn-link"


applyColorStyle : ColorPalette msg -> List (Html.Attribute msg)
applyColorStyle colorPalette =
    [ colorPalette ]



-- SIZES


sizeStyle :
    { config
        | size : ButtonSize
        , width : ButtonWidth
    }
    -> List (Html.Attribute a)
sizeStyle { size, width } =
    let
        config =
            sizeConfig size

        buttonAttributes =
            buttonWidthToStyle config width
    in
    List.concat [ config.attributes, buttonAttributes ]


sizeConfig : ButtonSize -> { attributes : List (Html.Attribute a), minWidth : Float }
sizeConfig size =
    case size of
        Tiny ->
            { attributes = [ class "btn-xs" ], minWidth = 16 }

        Small ->
            { attributes = [ class "btn-sm" ], minWidth = 16 }

        Medium ->
            { attributes = [ class "btn-md" ], minWidth = 20 }

        Large ->
            { attributes = [ class "btn-lg" ], minWidth = 24 }


buttonWidthToStyle : { config | minWidth : Float } -> ButtonWidth -> List (Html.Attribute a)
buttonWidthToStyle config width =
    case width of
        WidthExact pxWidth ->
            [ class "max-w-full"
            , A.style "width" (String.fromInt pxWidth ++ "px")
            , A.style "min-width" (String.fromFloat config.minWidth ++ "px")
            ]

        WidthUnbounded ->
            -- [ class "btn-wide" ]
            []

        WidthFillContainer ->
            [ class "w-full" ]

        WidthBounded { min, max } ->
            [ class "min-w-fit"
            , A.style "min-width" (String.fromInt min ++ "px")
            , A.style "max-width" (String.fromInt max ++ "px")
            ]
