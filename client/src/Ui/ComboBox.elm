module Ui.ComboBox exposing
    ( Attribute
    , State
    , choices
    , defaultState
    , errorIf
    , errorMessage
    , filter
    , groupedChoices
    , picked
    , view
    )

-- import Html.Attributes.Aria exposing (ariaLive)

import Accessibility.Live as Live
import Html exposing (Html, a, div, option)
import Html.Attributes as A exposing (class)
import Html.Events as E
import Ui.Error exposing (ErrorState)
import Ui.Utils


{-| Filter to pick a choice from the opt lists
-}
filter : (String -> List (Choice value)) -> Attribute value
filter filter_ =
    Attribute (\config -> { config | filter = Just filter_ })


{-| Groupings of choices (will be added _after_ isolated choices.)
-}
type alias ChoicesGroup value =
    { label : String
    , choices : List (Choice value)
    }


{-| -}
groupedChoices : (value -> String) -> List (ChoicesGroup value) -> Attribute value
groupedChoices valueToString optgroups =
    Attribute
        (\config ->
            { config
                | valueToString = Just valueToString
                , optgroups = optgroups
            }
        )


{-| A single possible choice.
-}
type alias Choice value =
    { label : String, value : value }


{-| -}
choices : (value -> String) -> List (Choice value) -> Attribute value
choices valueToString choices_ =
    Attribute
        (\config ->
            { config
                | valueToString = Just valueToString
                , choices = choices_
            }
        )


{-| Sets whether or not the field will be highlighted as having a validation error.
-}
errorIf : Bool -> Attribute value
errorIf =
    Attribute << Ui.Error.setErrorIf


{-| If `Just`, the field will be highlighted as having a validation error,
and the given error message will be shown.
-}
errorMessage : Maybe String -> Attribute value
errorMessage =
    Attribute << Ui.Error.setErrorMessage


{-| Customizations for the ComboBox
-}
type Attribute value
    = Attribute (Config value -> Config value)


type alias Config value =
    { id : Maybe String
    , choices : List (Choice value)
    , optgroups : List (ChoicesGroup value)
    , filter : Maybe (String -> List (Choice value))
    , valueToString : Maybe (value -> String)
    , error : ErrorState
    , hideLabel : Bool
    }


defaultConfig : Config value
defaultConfig =
    { id = Nothing
    , choices = []
    , optgroups = []
    , filter = Nothing
    , valueToString = Nothing
    , error = Ui.Error.noError
    , hideLabel = False
    }


type State value
    = State
        { openList : Bool
        , picked : Maybe value
        , inputString : String
        , index : Maybe Int
        }


defaultState : State value
defaultState =
    State
        { openList = False
        , picked = Nothing
        , inputString = ""
        , index = Nothing
        }


picked : State value -> Maybe value
picked (State state) =
    state.picked


applyConfig : List (Attribute value) -> Config value
applyConfig attributes =
    List.foldl (\(Attribute update) config -> update config) defaultConfig attributes


{-| Render the ComboBox as HTML.
-}
view =
    view1


view1 : String -> State value -> List (Attribute value) -> Html (State value)
view1 label (State state) attributes =
    let
        config =
            applyConfig attributes

        inputId =
            case config.id of
                Just id_ ->
                    id_

                Nothing ->
                    Ui.Utils.generateId label

        isInError =
            Ui.Error.ifError config.error

        choices_ =
            case config.filter of
                Just filter_ ->
                    filter_ state.inputString

                Nothing ->
                    config.choices

        toChoice :
            (value -> String)
            -> { value : value, label : String }
            -> { label : String, id : String, value : value, strValue : String }
        toChoice valueToString choice =
            let
                strValue =
                    valueToString choice.value
            in
            { label = choice.label
            , id = Ui.Utils.generateId strValue
            , value = choice.value
            , strValue = strValue
            }

        optionStringChoices :
            List
                { label : String
                , id : String
                , value : value
                , strValue : String
                }
        optionStringChoices =
            case config.valueToString of
                Just valueToString ->
                    List.map (toChoice valueToString) choices_

                Nothing ->
                    []

        currentValue =
            if state.picked == Nothing then
                config.choices |> List.head |> Maybe.map .value

            else
                state.picked

        keyControl : Int -> State value
        keyControl keyCode =
            case keyCode of
                38 ->
                    State
                        { state
                            | index = Maybe.map (\n -> max (n - 1) 0) state.index
                        }

                40 ->
                    State
                        { state
                            | index =
                                case state.index of
                                    Nothing ->
                                        Just 0

                                    Just n ->
                                        Just (n + 1)
                        }

                _ ->
                    State state
    in
    div []
        [ div []
            [ div []
                [ Html.label
                    [ class "block text-sm font-semibold leading-6 text-gray-900"
                    , if config.hideLabel then
                        class "hidden"

                      else
                        class ""
                    ]
                    [ Html.text label ]
                ]
            , div []
                [ Html.input
                    [ E.onFocus (State { state | openList = True })
                    , E.onInput (\s -> State { state | inputString = s, picked = Nothing })

                    -- , Ui.Utils.onKey (\keyCode -> keyControl keyCode)
                    , case state.picked of
                        Just value ->
                            case config.valueToString of
                                Just valueToString ->
                                    A.value (valueToString value)

                                Nothing ->
                                    class ""

                        Nothing ->
                            A.value state.inputString
                    , A.class "border rounded px-2 py-2 w-full"
                    , A.classList
                        [ ( "ring-2 ring-red-600", isInError )
                        , ( "outline-0 ring-2 focus:ring-2 focus-within:ring-red-600", isInError )
                        ]
                    ]
                    []
                ]
            ]
        , div [] <| Ui.Error.view inputId config
        , if state.openList then
            div [ class "relative" ]
                [ Html.select
                    [ class "absolute mt-2 max-h-48 w-full overflow-y-scroll border shadow-sm z-10 bg-white text-sm"
                    , A.size 20
                    ]
                    (List.indexedMap
                        (viewChoice currentValue (State state))
                        optionStringChoices
                    )
                ]

          else
            Html.text ""
        ]


{-| Render the ComboBox as HTML.
-}
view2 : String -> State value -> List (Attribute value) -> Html (State value)
view2 label (State state) attributes =
    let
        config =
            applyConfig attributes

        inputId =
            case config.id of
                Just id_ ->
                    id_

                Nothing ->
                    Ui.Utils.generateId label

        isInError =
            Ui.Error.ifError config.error

        choices_ =
            case config.filter of
                Just filter_ ->
                    filter_ state.inputString

                Nothing ->
                    config.choices

        toChoice :
            (value -> String)
            -> { value : value, label : String }
            -> { label : String, id : String, value : value, strValue : String }
        toChoice valueToString choice =
            let
                strValue =
                    valueToString choice.value
            in
            { label = choice.label
            , id = Ui.Utils.generateId strValue
            , value = choice.value
            , strValue = strValue
            }

        optionStringChoices :
            List
                { label : String
                , id : String
                , value : value
                , strValue : String
                }
        optionStringChoices =
            case config.valueToString of
                Just valueToString ->
                    List.map (toChoice valueToString) choices_

                Nothing ->
                    []

        currentValue =
            if state.picked == Nothing then
                config.choices |> List.head |> Maybe.map .value

            else
                state.picked

        keyControl : Int -> State value
        keyControl keyCode =
            case keyCode of
                38 ->
                    State
                        { state
                            | index = Maybe.map (\n -> max (n - 1) 0) state.index
                        }

                40 ->
                    State
                        { state
                            | index =
                                case state.index of
                                    Nothing ->
                                        Just 0

                                    Just n ->
                                        Just (n + 1)
                        }

                _ ->
                    State state
    in
    div []
        [ div []
            [ div []
                [ Html.label
                    [ class "block text-sm font-semibold leading-6 text-gray-900"
                    , if config.hideLabel then
                        class "hidden"

                      else
                        class ""
                    ]
                    [ Html.text label ]
                ]
            , div []
                [ Html.input
                    [ E.onFocus (State { state | openList = True })
                    , E.onInput (\s -> State { state | inputString = s, picked = Nothing })
                    , Ui.Utils.onKey (\keyCode -> keyControl keyCode)
                    , case state.picked of
                        Just value ->
                            case config.valueToString of
                                Just valueToString ->
                                    A.value (valueToString value)

                                Nothing ->
                                    class ""

                        Nothing ->
                            A.value state.inputString
                    , A.class "border rounded px-2 py-2 w-full"
                    , A.classList
                        [ ( "ring-2 ring-red-600", isInError )
                        , ( "outline-0 ring-2 focus:ring-2 focus-within:ring-red-600", isInError )
                        ]
                    , A.autocomplete False
                    , A.attribute "autocorrect" "off"
                    , A.attribute "autocapitalize" "off"
                    , Live.off
                    ]
                    []
                ]
            ]
        , div [] <| Ui.Error.view inputId config
        , if state.openList then
            div [ class "relative" ]
                [ div
                    [ class "absolute mt-2 max-h-48 w-full overflow-y-scroll border shadow-sm z-10 bg-white text-sm"
                    ]
                    (List.indexedMap
                        (viewChoice currentValue (State state))
                        optionStringChoices
                    )
                ]

          else
            Html.text ""
        ]


viewDefaultChoice : Maybe msg -> String -> Html msg
viewDefaultChoice current displayText =
    Html.option
        [ A.selected (current == Nothing)
        , A.disabled True
        ]
        [ Html.text displayText ]


viewChoice :
    Maybe value
    -> State value
    -> Int
    ->
        { label : String
        , id : String
        , value : value
        , strValue : String
        }
    -> Html (State value)
viewChoice current (State state) index config =
    Html.option
        [ A.id config.id
        , A.selected (current == Just config.value)
        , A.value config.strValue
        , E.onClick (State { state | picked = Just config.value, openList = False })
        , class "p-2 hover:bg-gray-200"
        , if state.index == Just index then
            class "bg-gray-200"

          else
            class ""
        ]
        [ Html.text config.label ]
