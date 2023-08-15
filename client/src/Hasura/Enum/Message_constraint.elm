-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Hasura.Enum.Message_constraint exposing (..)

import Json.Decode as Decode exposing (Decoder)


{-| unique or primary key constraints on table "message"

  - Message\_pkey - unique or primary key constraint on columns "id"

-}
type Message_constraint
    = Message_pkey


list : List Message_constraint
list =
    [ Message_pkey ]


decoder : Decoder Message_constraint
decoder =
    Decode.string
        |> Decode.andThen
            (\string ->
                case string of
                    "message_pkey" ->
                        Decode.succeed Message_pkey

                    _ ->
                        Decode.fail ("Invalid Message_constraint type, " ++ string ++ " try re-running the @dillonkearns/elm-graphql CLI ")
            )


{-| Convert from the union type representing the Enum to a string that the GraphQL server will recognize.
-}
toString : Message_constraint -> String
toString enum____ =
    case enum____ of
        Message_pkey ->
            "message_pkey"


{-| Convert from a String representation to an elm representation enum.
This is the inverse of the Enum `toString` function. So you can call `toString` and then convert back `fromString` safely.

    Swapi.Enum.Episode.NewHope
        |> Swapi.Enum.Episode.toString
        |> Swapi.Enum.Episode.fromString
        == Just NewHope

This can be useful for generating Strings to use for <select> menus to check which item was selected.

-}
fromString : String -> Maybe Message_constraint
fromString enumString____ =
    case enumString____ of
        "message_pkey" ->
            Just Message_pkey

        _ ->
            Nothing