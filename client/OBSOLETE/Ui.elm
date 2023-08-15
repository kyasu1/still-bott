module Ui exposing
    ( RadioGroupOption
    , Size(..)
    , Variant(..)
    , VariantColor(..)
    , button
    , link
    , linkExternal
    , none
    , radioGroup
    , textInput
    , toggle
    )

import Accessibility.Aria as Aria
import Accessibility.Role as Role
import Html exposing (..)
import Html.Attributes as A exposing (class, href)
import Html.Events as E


none : Html msg
none =
    text ""


type Variant
    = Solid
    | Outline
    | Ghost
    | Link


type VariantColor
    = Primary
    | Secondary
    | Black


type Size
    = Xs
    | Sm
    | Md
    | Lg
    | Xl


linkBase : Bool -> List (Attribute msg) -> { url : String, label : Html msg } -> Html msg
linkBase isExternal attrs { url, label } =
    a (href url :: attrs) [ label ]


link : { url : String, label : Html msg } -> Html msg
link args =
    linkBase False [ class "flex items-center whitespace-nowrap rounded py-2 px-6 font-medium transition-colors duration-200 hover:text-white lg:py-0 lg:px-0 lg:text-sm text-gray-400" ] args


linkExternal : { url : String, label : Html msg } -> Html msg
linkExternal args =
    linkBase True [ class "flex items-center whitespace-nowrap rounded py-2 px-6 font-medium transition-colors duration-200 hover:text-white lg:py-0 lg:px-0 lg:text-sm text-gray-400" ] args


buttonBase : List (Attribute msg) -> { onPress : Maybe msg, label : Html msg } -> Html msg
buttonBase attrs { onPress, label } =
    Html.button
        (attrs
            ++ [ case onPress of
                    Just msg ->
                        E.onClick msg

                    Nothing ->
                        A.disabled True
               ]
        )
        [ label ]


button : Variant -> VariantColor -> Size -> { onPress : Maybe msg, label : Html msg } -> Html msg
button v c s args =
    let
        base =
            class "rounded-lg border text-center font-medium shadow-sm transition-all focus:ring disabled:cursor-not-allowed w-full"

        size =
            case s of
                Xs ->
                    class "px-3 py-1.5 text-xs"

                Sm ->
                    class "px-4 py-2 text-sm"

                Md ->
                    class "px-5 py-2.5 text-sm"

                Lg ->
                    class "px-6 py-3 text-base"

                Xl ->
                    class "px-8 py-4 text-lg"

        variant =
            case v of
                Solid ->
                    case c of
                        Primary ->
                            class "border-primary-500 bg-primary-500 text-white hover:border-primary-700 hover:bg-primary-700 focus:ring-primary-200 disabled:border-primary-300 disabled:bg-primary-300"

                        Secondary ->
                            class "border-secondary-500 bg-secondary-500 text-white hover:border-secondary-700 hover:bg-secondary-700 focus:ring-secondary-200 disabled:border-secondary-300 disabled:bg-secondary-300"

                        Black ->
                            class "border-gray-700 bg-gray-700 text-white hover:border-gray-900 hover:bg-gray-900 focus:ring-gray-200 disabled:border-gray-300 disabled:bg-gray-300"

                Outline ->
                    case c of
                        Primary ->
                            class "border-gray-300 bg-white text-primary-500 hover:bg-gray-100 focus:ring-gray-100 disabled:border-gray-100 disabled:bg-gray-50 disabled:text-gray-400"

                        Secondary ->
                            class "border-gray-300 bg-white text-secondary-700 hover:bg-gray-100 focus:ring-gray-100 disabled:border-gray-100 disabled:bg-gray-50 disabled:text-gray-400"

                        Black ->
                            class "border-gray-300 bg-white text-gray-700 hover:bg-gray-100 focus:ring-gray-100 disabled:border-gray-100 disabled:bg-gray-50 disabled:text-gray-400"

                Ghost ->
                    case c of
                        Primary ->
                            class "border-primary-100 bg-primary-100 text-primary-600 hover:border-primary-200 hover:bg-primary-200 focus:ring-primary-50 disabled:border-primary-50 disabled:bg-primary-50 disabled:text-primary-400"

                        Secondary ->
                            class "border-secondary-100 bg-secondary-100 text-secondary-600 hover:border-secondary-200 hover:bg-secondary-200 focus:ring-secondary-50 disabled:border-secondary-50 disabled:bg-secondary-50 disabled:text-secondary-400"

                        Black ->
                            class "border-gray-100 bg-gray-100 text-gray-600 hover:border-gray-200 hover:bg-gray-200 focus:ring-gray-50 disabled:border-gray-50 disabled:bg-gray-50 disabled:text-gray-400"

                Link ->
                    class "border-transparent bg-transparent text-gray-700 shadow-none hover:bg-gray-100 disabled:bg-transparent disabled:text-gray-400"
    in
    buttonBase [ base, size, variant ] args



--


radioGroup :
    { label : String
    , name : String
    , options : List (RadioGroupOption value)
    , picked : value
    , onPick : value -> msg
    }
    -> Html msg
radioGroup { label, name, options, picked, onPick } =
    fieldset []
        [ legend [ class "sr-only" ] [ text label ]
        , div [ class "flex flex-col sm:flex-row space-x-2 w-full" ] <| List.indexedMap (radioGroupOption name picked onPick) options
        ]


radioGroupOption : String -> value -> (value -> msg) -> Int -> RadioGroupOption value -> Html msg
radioGroupOption name picked handleClick index o =
    let
        attrsInput =
            if picked == o.value then
                []

            else
                [ E.onClick (handleClick o.value) ]

        id =
            name ++ String.fromInt index
    in
    label
        [ A.classList
            [ ( "flex items-center justify-center rounded-md py-3 px-3 text-sm font-semibold uppercase sm:flex-1 cursor-pointer focus:outline-none", True )
            , ( "bg-primary-600 text-white hover:bg-primary-500", picked == o.value )
            , ( "ring-1 ring-inset ring-gray-300 bg-white text-gray-900 hover:bg-gray-50", picked /= o.value )
            , ( "ring-2 ring-indigo-600 ring-offset-2", picked == o.value )
            ]
        ]
        [ input
            ([ A.type_ "radio"
             , A.name name
             , class "sr-only"
             , Aria.labeledBy id
             ]
                ++ attrsInput
            )
            []
        , span [ A.id id ] [ text o.label ]
        ]


type alias RadioGroupOption value =
    { value : value
    , label : String
    }



--


textInput : List (Html.Attribute msg) -> { label : String, name : String, value : String, onChange : String -> msg } -> List (Html msg)
textInput attrs args =
    [ label [ class "mb-1 block text-sm font-medium text-gray-700 after:ml-0.5 after:text-red-500 after:content-['*']" ] [ text args.label ]
    , input
        (attrs
            ++ [ A.type_ "text"
               , A.id args.name
               , A.value args.value
               , E.onInput args.onChange
               , class "block w-full rounded-md border-red-300 shadow-sm focus:border-red-300 focus:ring focus:ring-red-200 focus:ring-opacity-50 disabled:cursor-not-allowed disabled:bg-gray-50 disabled:text-gray-500"
               ]
        )
        []
    , p [ class "mt-1 text-sm text-red-500" ] []
    ]



--


checkbox : { label : String, name : String, value : String, onClick : msg } -> Html msg
checkbox args =
    div
        [ class "relative flex items-start" ]
        [ div [ class "flex h-6 items-center" ]
            [ input [ A.id "candidates", A.name args.name, A.type_ "checkbox", class "h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-600" ] []
            ]
        , div [ class "ml-3 text-sm leading-6" ]
            [ label [ A.for "candidates", A.class "font-medium text-gray-900" ] [ text "Candidates" ]
            , p [ A.id "candidates-description", class "text-gray-500" ] [ text "Get notified when a candidate applies for a job." ]
            ]
        ]



--


toggle : Bool -> msg -> Html msg
toggle state onClick =
    Html.button
        [ A.type_ "button"
        , if state then
            class "bg-indigo-600"

          else
            class "bg-gray-200"
        , class "relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2"
        , Role.switch
        , Aria.checked (Just state)
        , E.onClick onClick
        ]
        [ span [ class "sr-only" ] [ text "label" ]
        , span
            [ Aria.hidden True
            , if state then
                class "translate-x-5"

              else
                class "translate-x-0"
            , class "slate-x-0 pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out"
            ]
            []
        ]



-- <!-- Enabled: "bg-indigo-600", Not Enabled: "bg-gray-200" -->
-- <button type="button" class="bg-gray-200 relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2" role="switch" aria-checked="false">
--   <span class="sr-only">Use setting</span>
--   <!-- Enabled: "translate-x-5", Not Enabled: "translate-x-0" -->
--   <span aria-hidden="true" class="translate-x-0 pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out"></span>
-- </button>
