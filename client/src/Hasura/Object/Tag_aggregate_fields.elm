-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Hasura.Object.Tag_aggregate_fields exposing (..)

import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Hasura.Enum.Tag_select_column
import Hasura.InputObject
import Hasura.Interface
import Hasura.Object
import Hasura.Scalar
import Hasura.Union
import Json.Decode as Decode
import ScalarCodecs


type alias CountOptionalArguments =
    { columns : OptionalArgument (List Hasura.Enum.Tag_select_column.Tag_select_column)
    , distinct : OptionalArgument Bool
    }


count :
    (CountOptionalArguments -> CountOptionalArguments)
    -> SelectionSet Int Hasura.Object.Tag_aggregate_fields
count fillInOptionals____ =
    let
        filledInOptionals____ =
            fillInOptionals____ { columns = Absent, distinct = Absent }

        optionalArgs____ =
            [ Argument.optional "columns" filledInOptionals____.columns (Encode.enum Hasura.Enum.Tag_select_column.toString |> Encode.list), Argument.optional "distinct" filledInOptionals____.distinct Encode.bool ]
                |> List.filterMap Basics.identity
    in
    Object.selectionForField "Int" "count" optionalArgs____ Decode.int


max :
    SelectionSet decodesTo Hasura.Object.Tag_max_fields
    -> SelectionSet (Maybe decodesTo) Hasura.Object.Tag_aggregate_fields
max object____ =
    Object.selectionForCompositeField "max" [] object____ (Basics.identity >> Decode.nullable)


min :
    SelectionSet decodesTo Hasura.Object.Tag_min_fields
    -> SelectionSet (Maybe decodesTo) Hasura.Object.Tag_aggregate_fields
min object____ =
    Object.selectionForCompositeField "min" [] object____ (Basics.identity >> Decode.nullable)
