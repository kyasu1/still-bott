-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Hasura.Object.Task_fixed_time exposing (..)

import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Hasura.InputObject
import Hasura.Interface
import Hasura.Object
import Hasura.Scalar
import Hasura.Union
import Json.Decode as Decode
import ScalarCodecs


created_at : SelectionSet ScalarCodecs.Timestamptz Hasura.Object.Task_fixed_time
created_at =
    Object.selectionForField "ScalarCodecs.Timestamptz" "created_at" [] (ScalarCodecs.codecs |> Hasura.Scalar.unwrapCodecs |> .codecTimestamptz |> .decoder)


enabled : SelectionSet Bool Hasura.Object.Task_fixed_time
enabled =
    Object.selectionForField "Bool" "enabled" [] Decode.bool


fri : SelectionSet Bool Hasura.Object.Task_fixed_time
fri =
    Object.selectionForField "Bool" "fri" [] Decode.bool


id : SelectionSet ScalarCodecs.Uuid Hasura.Object.Task_fixed_time
id =
    Object.selectionForField "ScalarCodecs.Uuid" "id" [] (ScalarCodecs.codecs |> Hasura.Scalar.unwrapCodecs |> .codecUuid |> .decoder)


mon : SelectionSet Bool Hasura.Object.Task_fixed_time
mon =
    Object.selectionForField "Bool" "mon" [] Decode.bool


random : SelectionSet Bool Hasura.Object.Task_fixed_time
random =
    Object.selectionForField "Bool" "random" [] Decode.bool


sat : SelectionSet Bool Hasura.Object.Task_fixed_time
sat =
    Object.selectionForField "Bool" "sat" [] Decode.bool


sun : SelectionSet Bool Hasura.Object.Task_fixed_time
sun =
    Object.selectionForField "Bool" "sun" [] Decode.bool


{-| An object relationship
-}
tag :
    SelectionSet decodesTo Hasura.Object.Tag
    -> SelectionSet (Maybe decodesTo) Hasura.Object.Task_fixed_time
tag object____ =
    Object.selectionForCompositeField "tag" [] object____ (Basics.identity >> Decode.nullable)


tag_id : SelectionSet (Maybe ScalarCodecs.Uuid) Hasura.Object.Task_fixed_time
tag_id =
    Object.selectionForField "(Maybe ScalarCodecs.Uuid)" "tag_id" [] (ScalarCodecs.codecs |> Hasura.Scalar.unwrapCodecs |> .codecUuid |> .decoder |> Decode.nullable)


thu : SelectionSet Bool Hasura.Object.Task_fixed_time
thu =
    Object.selectionForField "Bool" "thu" [] Decode.bool


tue : SelectionSet Bool Hasura.Object.Task_fixed_time
tue =
    Object.selectionForField "Bool" "tue" [] Decode.bool


tweet_at : SelectionSet ScalarCodecs.Time Hasura.Object.Task_fixed_time
tweet_at =
    Object.selectionForField "ScalarCodecs.Time" "tweet_at" [] (ScalarCodecs.codecs |> Hasura.Scalar.unwrapCodecs |> .codecTime |> .decoder)


updated_at : SelectionSet ScalarCodecs.Timestamptz Hasura.Object.Task_fixed_time
updated_at =
    Object.selectionForField "ScalarCodecs.Timestamptz" "updated_at" [] (ScalarCodecs.codecs |> Hasura.Scalar.unwrapCodecs |> .codecTimestamptz |> .decoder)


{-| An object relationship
-}
user :
    SelectionSet decodesTo Hasura.Object.User
    -> SelectionSet decodesTo Hasura.Object.Task_fixed_time
user object____ =
    Object.selectionForCompositeField "user" [] object____ Basics.identity


user_id : SelectionSet String Hasura.Object.Task_fixed_time
user_id =
    Object.selectionForField "String" "user_id" [] Decode.string


wed : SelectionSet Bool Hasura.Object.Task_fixed_time
wed =
    Object.selectionForField "Bool" "wed" [] Decode.bool