-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Hasura.Enum.Role_constraint exposing (..)

import Json.Decode as Decode exposing (Decoder)


{-| unique or primary key constraints on table "role"

  - Role\_pkey - unique or primary key constraint on columns "value"

-}
type Role_constraint
    = Role_pkey


list : List Role_constraint
list =
    [ Role_pkey ]


decoder : Decoder Role_constraint
decoder =
    Decode.string
        |> Decode.andThen
            (\string ->
                case string of
                    "role_pkey" ->
                        Decode.succeed Role_pkey

                    _ ->
                        Decode.fail ("Invalid Role_constraint type, " ++ string ++ " try re-running the @dillonkearns/elm-graphql CLI ")
            )


{-| Convert from the union type representing the Enum to a string that the GraphQL server will recognize.
-}
toString : Role_constraint -> String
toString enum____ =
    case enum____ of
        Role_pkey ->
            "role_pkey"


{-| Convert from a String representation to an elm representation enum.
This is the inverse of the Enum `toString` function. So you can call `toString` and then convert back `fromString` safely.

    Swapi.Enum.Episode.NewHope
        |> Swapi.Enum.Episode.toString
        |> Swapi.Enum.Episode.fromString
        == Just NewHope

This can be useful for generating Strings to use for <select> menus to check which item was selected.

-}
fromString : String -> Maybe Role_constraint
fromString enumString____ =
    case enumString____ of
        "role_pkey" ->
            Just Role_pkey

        _ ->
            Nothing
