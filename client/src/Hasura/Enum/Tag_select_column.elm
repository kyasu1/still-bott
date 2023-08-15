-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Hasura.Enum.Tag_select_column exposing (..)

import Json.Decode as Decode exposing (Decoder)


{-| select columns of table "tag"

  - Description - column name
  - Id - column name
  - Name - column name
  - User\_id - column name

-}
type Tag_select_column
    = Description
    | Id
    | Name
    | User_id


list : List Tag_select_column
list =
    [ Description, Id, Name, User_id ]


decoder : Decoder Tag_select_column
decoder =
    Decode.string
        |> Decode.andThen
            (\string ->
                case string of
                    "description" ->
                        Decode.succeed Description

                    "id" ->
                        Decode.succeed Id

                    "name" ->
                        Decode.succeed Name

                    "user_id" ->
                        Decode.succeed User_id

                    _ ->
                        Decode.fail ("Invalid Tag_select_column type, " ++ string ++ " try re-running the @dillonkearns/elm-graphql CLI ")
            )


{-| Convert from the union type representing the Enum to a string that the GraphQL server will recognize.
-}
toString : Tag_select_column -> String
toString enum____ =
    case enum____ of
        Description ->
            "description"

        Id ->
            "id"

        Name ->
            "name"

        User_id ->
            "user_id"


{-| Convert from a String representation to an elm representation enum.
This is the inverse of the Enum `toString` function. So you can call `toString` and then convert back `fromString` safely.

    Swapi.Enum.Episode.NewHope
        |> Swapi.Enum.Episode.toString
        |> Swapi.Enum.Episode.fromString
        == Just NewHope

This can be useful for generating Strings to use for <select> menus to check which item was selected.

-}
fromString : String -> Maybe Tag_select_column
fromString enumString____ =
    case enumString____ of
        "description" ->
            Just Description

        "id" ->
            Just Id

        "name" ->
            Just Name

        "user_id" ->
            Just User_id

        _ ->
            Nothing
