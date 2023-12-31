-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Hasura.Enum.Task_fixed_time_select_column_task_fixed_time_aggregate_bool_exp_bool_or_arguments_columns exposing (..)

import Json.Decode as Decode exposing (Decoder)


{-| select "task\_fixed\_time\_aggregate\_bool\_exp\_bool\_or\_arguments\_columns" columns of table "task\_fixed\_time"

  - Enabled - column name
  - Fri - column name
  - Mon - column name
  - Random - column name
  - Sat - column name
  - Sun - column name
  - Thu - column name
  - Tue - column name
  - Wed - column name

-}
type Task_fixed_time_select_column_task_fixed_time_aggregate_bool_exp_bool_or_arguments_columns
    = Enabled
    | Fri
    | Mon
    | Random
    | Sat
    | Sun
    | Thu
    | Tue
    | Wed


list : List Task_fixed_time_select_column_task_fixed_time_aggregate_bool_exp_bool_or_arguments_columns
list =
    [ Enabled, Fri, Mon, Random, Sat, Sun, Thu, Tue, Wed ]


decoder : Decoder Task_fixed_time_select_column_task_fixed_time_aggregate_bool_exp_bool_or_arguments_columns
decoder =
    Decode.string
        |> Decode.andThen
            (\string ->
                case string of
                    "enabled" ->
                        Decode.succeed Enabled

                    "fri" ->
                        Decode.succeed Fri

                    "mon" ->
                        Decode.succeed Mon

                    "random" ->
                        Decode.succeed Random

                    "sat" ->
                        Decode.succeed Sat

                    "sun" ->
                        Decode.succeed Sun

                    "thu" ->
                        Decode.succeed Thu

                    "tue" ->
                        Decode.succeed Tue

                    "wed" ->
                        Decode.succeed Wed

                    _ ->
                        Decode.fail ("Invalid Task_fixed_time_select_column_task_fixed_time_aggregate_bool_exp_bool_or_arguments_columns type, " ++ string ++ " try re-running the @dillonkearns/elm-graphql CLI ")
            )


{-| Convert from the union type representing the Enum to a string that the GraphQL server will recognize.
-}
toString : Task_fixed_time_select_column_task_fixed_time_aggregate_bool_exp_bool_or_arguments_columns -> String
toString enum____ =
    case enum____ of
        Enabled ->
            "enabled"

        Fri ->
            "fri"

        Mon ->
            "mon"

        Random ->
            "random"

        Sat ->
            "sat"

        Sun ->
            "sun"

        Thu ->
            "thu"

        Tue ->
            "tue"

        Wed ->
            "wed"


{-| Convert from a String representation to an elm representation enum.
This is the inverse of the Enum `toString` function. So you can call `toString` and then convert back `fromString` safely.

    Swapi.Enum.Episode.NewHope
        |> Swapi.Enum.Episode.toString
        |> Swapi.Enum.Episode.fromString
        == Just NewHope

This can be useful for generating Strings to use for <select> menus to check which item was selected.

-}
fromString : String -> Maybe Task_fixed_time_select_column_task_fixed_time_aggregate_bool_exp_bool_or_arguments_columns
fromString enumString____ =
    case enumString____ of
        "enabled" ->
            Just Enabled

        "fri" ->
            Just Fri

        "mon" ->
            Just Mon

        "random" ->
            Just Random

        "sat" ->
            Just Sat

        "sun" ->
            Just Sun

        "thu" ->
            Just Thu

        "tue" ->
            Just Tue

        "wed" ->
            Just Wed

        _ ->
            Nothing
