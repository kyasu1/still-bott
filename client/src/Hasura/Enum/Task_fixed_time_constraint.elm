-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Hasura.Enum.Task_fixed_time_constraint exposing (..)

import Json.Decode as Decode exposing (Decoder)


{-| unique or primary key constraints on table "task\_fixed\_time"

  - Task\_fixed\_time\_pkey - unique or primary key constraint on columns "id"

-}
type Task_fixed_time_constraint
    = Task_fixed_time_pkey


list : List Task_fixed_time_constraint
list =
    [ Task_fixed_time_pkey ]


decoder : Decoder Task_fixed_time_constraint
decoder =
    Decode.string
        |> Decode.andThen
            (\string ->
                case string of
                    "task_fixed_time_pkey" ->
                        Decode.succeed Task_fixed_time_pkey

                    _ ->
                        Decode.fail ("Invalid Task_fixed_time_constraint type, " ++ string ++ " try re-running the @dillonkearns/elm-graphql CLI ")
            )


{-| Convert from the union type representing the Enum to a string that the GraphQL server will recognize.
-}
toString : Task_fixed_time_constraint -> String
toString enum____ =
    case enum____ of
        Task_fixed_time_pkey ->
            "task_fixed_time_pkey"


{-| Convert from a String representation to an elm representation enum.
This is the inverse of the Enum `toString` function. So you can call `toString` and then convert back `fromString` safely.

    Swapi.Enum.Episode.NewHope
        |> Swapi.Enum.Episode.toString
        |> Swapi.Enum.Episode.fromString
        == Just NewHope

This can be useful for generating Strings to use for <select> menus to check which item was selected.

-}
fromString : String -> Maybe Task_fixed_time_constraint
fromString enumString____ =
    case enumString____ of
        "task_fixed_time_pkey" ->
            Just Task_fixed_time_pkey

        _ ->
            Nothing
