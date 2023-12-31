-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Hasura.Enum.Role_select_column exposing (..)

import Json.Decode as Decode exposing (Decoder)


{-| select columns of table "role"

  - Value - column name

-}
type Role_select_column
    = Value


list : List Role_select_column
list =
    [ Value ]


decoder : Decoder Role_select_column
decoder =
    Decode.string
        |> Decode.andThen
            (\string ->
                case string of
                    "value" ->
                        Decode.succeed Value

                    _ ->
                        Decode.fail ("Invalid Role_select_column type, " ++ string ++ " try re-running the @dillonkearns/elm-graphql CLI ")
            )


{-| Convert from the union type representing the Enum to a string that the GraphQL server will recognize.
-}
toString : Role_select_column -> String
toString enum____ =
    case enum____ of
        Value ->
            "value"


{-| Convert from a String representation to an elm representation enum.
This is the inverse of the Enum `toString` function. So you can call `toString` and then convert back `fromString` safely.

    Swapi.Enum.Episode.NewHope
        |> Swapi.Enum.Episode.toString
        |> Swapi.Enum.Episode.fromString
        == Just NewHope

This can be useful for generating Strings to use for <select> menus to check which item was selected.

-}
fromString : String -> Maybe Role_select_column
fromString enumString____ =
    case enumString____ of
        "value" ->
            Just Value

        _ ->
            Nothing
