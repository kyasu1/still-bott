-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Hasura.Enum.Media_constraint exposing (..)

import Json.Decode as Decode exposing (Decoder)


{-| unique or primary key constraints on table "media"

  - Media\_pkey - unique or primary key constraint on columns "id"

-}
type Media_constraint
    = Media_pkey


list : List Media_constraint
list =
    [ Media_pkey ]


decoder : Decoder Media_constraint
decoder =
    Decode.string
        |> Decode.andThen
            (\string ->
                case string of
                    "media_pkey" ->
                        Decode.succeed Media_pkey

                    _ ->
                        Decode.fail ("Invalid Media_constraint type, " ++ string ++ " try re-running the @dillonkearns/elm-graphql CLI ")
            )


{-| Convert from the union type representing the Enum to a string that the GraphQL server will recognize.
-}
toString : Media_constraint -> String
toString enum____ =
    case enum____ of
        Media_pkey ->
            "media_pkey"


{-| Convert from a String representation to an elm representation enum.
This is the inverse of the Enum `toString` function. So you can call `toString` and then convert back `fromString` safely.

    Swapi.Enum.Episode.NewHope
        |> Swapi.Enum.Episode.toString
        |> Swapi.Enum.Episode.fromString
        == Just NewHope

This can be useful for generating Strings to use for <select> menus to check which item was selected.

-}
fromString : String -> Maybe Media_constraint
fromString enumString____ =
    case enumString____ of
        "media_pkey" ->
            Just Media_pkey

        _ ->
            Nothing
