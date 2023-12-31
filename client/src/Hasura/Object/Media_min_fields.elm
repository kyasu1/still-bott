-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Hasura.Object.Media_min_fields exposing (..)

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


id : SelectionSet (Maybe ScalarCodecs.Uuid) Hasura.Object.Media_min_fields
id =
    Object.selectionForField "(Maybe ScalarCodecs.Uuid)" "id" [] (ScalarCodecs.codecs |> Hasura.Scalar.unwrapCodecs |> .codecUuid |> .decoder |> Decode.nullable)


thumbnail : SelectionSet (Maybe String) Hasura.Object.Media_min_fields
thumbnail =
    Object.selectionForField "(Maybe String)" "thumbnail" [] (Decode.string |> Decode.nullable)


uploaded_at : SelectionSet (Maybe ScalarCodecs.Timestamptz) Hasura.Object.Media_min_fields
uploaded_at =
    Object.selectionForField "(Maybe ScalarCodecs.Timestamptz)" "uploaded_at" [] (ScalarCodecs.codecs |> Hasura.Scalar.unwrapCodecs |> .codecTimestamptz |> .decoder |> Decode.nullable)


user_id : SelectionSet (Maybe String) Hasura.Object.Media_min_fields
user_id =
    Object.selectionForField "(Maybe String)" "user_id" [] (Decode.string |> Decode.nullable)
