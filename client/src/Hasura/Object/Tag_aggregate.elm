-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Hasura.Object.Tag_aggregate exposing (..)

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


aggregate :
    SelectionSet decodesTo Hasura.Object.Tag_aggregate_fields
    -> SelectionSet (Maybe decodesTo) Hasura.Object.Tag_aggregate
aggregate object____ =
    Object.selectionForCompositeField "aggregate" [] object____ (Basics.identity >> Decode.nullable)


nodes :
    SelectionSet decodesTo Hasura.Object.Tag
    -> SelectionSet (List decodesTo) Hasura.Object.Tag_aggregate
nodes object____ =
    Object.selectionForCompositeField "nodes" [] object____ (Basics.identity >> Decode.list)
