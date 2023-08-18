module Ui.ClickableAttributes exposing
    ( ClickableAttributes
    , Config
    , href
    , init
    , linkExternal
    , linkSpa
    , onClick
    , submit
    , toButtonAttributes
    , toLinkAttributes
    )

-- import Html.Attributes.Aria as Aria

import Accessibility.Aria as Aria
import Accessibility.Key as Key
import Accessibility.Role as Role
import Heroicons.Outline as Outline
import Html
import Html.Attributes as A
import Html.Events as E
import Svg exposing (Svg)
import Svg.Attributes as SA
import TsJson.Codec exposing (string)
import Ui.AttributesExtra as AttributesExtra


{-| -}
type alias ClickableAttributes route msg =
    { linkType : Link
    , buttonType : String
    , url : Maybe route
    , urlString : Maybe String
    , onClick : Maybe msg
    , opensModal : Bool
    }


type Link
    = Default
      -- | WithTracking
    | SinglePageApp
      -- | WithMethod String
      -- | ExternalWithTracking
    | External


{-| -}
init : ClickableAttributes route msg
init =
    { linkType = Default
    , buttonType = "button"
    , url = Nothing
    , urlString = Nothing
    , onClick = Nothing
    , opensModal = False
    }


{-| -}
type alias Config attributes route msg =
    { attributes
        | clickableAttributes : ClickableAttributes route msg
        , rightIcon : Maybe (Svg msg)
    }


{-| -}
onClick : msg -> Config a route msg -> Config a route msg
onClick msg ({ clickableAttributes } as config) =
    { config | clickableAttributes = { clickableAttributes | onClick = Just msg } }


{-| -}
submit : Config a route msg -> Config a route msg
submit ({ clickableAttributes } as config) =
    { config | clickableAttributes = { clickableAttributes | buttonType = "submit" } }


{-| -}
href : route -> Config a route msg -> Config a route msg
href url ({ clickableAttributes } as config) =
    { config | clickableAttributes = { clickableAttributes | url = Just url } }


{-| -}
linkExternal : String -> Config a route msg -> Config a route msg
linkExternal url =
    withExternalAffordance >> linkExternalInternal url


{-| -}
linkExternalInternal : String -> { attributes | clickableAttributes : ClickableAttributes route msg } -> { attributes | clickableAttributes : ClickableAttributes route msg }
linkExternalInternal url ({ clickableAttributes } as config) =
    { config
        | clickableAttributes =
            { clickableAttributes
                | linkType = External
                , urlString = Just url
            }
    }


{-| -}
linkSpa : route -> Config a route msg -> Config a route msg
linkSpa url ({ clickableAttributes } as config) =
    { config | clickableAttributes = { clickableAttributes | linkType = SinglePageApp, url = Just url } }


{-| -}
toButtonAttributes : ClickableAttributes route msg -> { disabled : Bool } -> List (Html.Attribute msg)
toButtonAttributes clickableAttributes { disabled } =
    [ AttributesExtra.maybe E.onClick clickableAttributes.onClick
    , A.type_ clickableAttributes.buttonType
    , -- why "aria-haspopup=true" instead of "aria-haspopup=dialog"?
      -- AT support for aria-haspopup=dialog is currently (Nov 2022) limited.
      -- See https://html5accessibility.com/stuff/2021/02/02/haspopup-haspoop/
      -- If time has passed, feel free to revisit and see if dialog support has improved!
      AttributesExtra.includeIf clickableAttributes.opensModal
        (A.attribute "aria-haspopup" "true")
    , A.disabled disabled
    ]


{-| -}
toLinkAttributes : { routeToString : route -> String, isDisabled : Bool } -> ClickableAttributes route msg -> List (Html.Attribute msg)
toLinkAttributes { routeToString, isDisabled } clickableAttributes =
    let
        attributes =
            toEnabledLinkAttributes routeToString clickableAttributes
    in
    if isDisabled then
        [ Role.link
        , Aria.disabled True
        ]

    else
        attributes


toEnabledLinkAttributes : (route -> String) -> ClickableAttributes route msg -> List (Html.Attribute msg)
toEnabledLinkAttributes routeToString clickableAttributes =
    let
        stringUrl =
            case ( clickableAttributes.urlString, clickableAttributes.url ) of
                ( Just url, _ ) ->
                    url

                ( _, Just route ) ->
                    routeToString route

                ( Nothing, Nothing ) ->
                    "#"
    in
    case clickableAttributes.linkType of
        Default ->
            [ A.href stringUrl
            , A.target "_self"
            ]

        SinglePageApp ->
            case clickableAttributes.onClick of
                Just handler ->
                    [ A.href stringUrl -- TODO: Prevent Default
                    ]

                Nothing ->
                    [ A.href stringUrl ]

        External ->
            [ A.href stringUrl
            , A.target "_blank"
            ]


withExternalAffordance : { attributes | rightIcon : Maybe (Svg msg) } -> { attributes | rightIcon : Maybe (Svg msg) }
withExternalAffordance config =
    { config | rightIcon = Just (Outline.arrowTopRightOnSquare [ SA.class "w-8 h-8" ]) }
