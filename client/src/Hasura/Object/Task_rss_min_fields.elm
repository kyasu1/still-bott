-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Hasura.Object.Task_rss_min_fields exposing (..)

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


created_at : SelectionSet (Maybe ScalarCodecs.Timestamptz) Hasura.Object.Task_rss_min_fields
created_at =
    Object.selectionForField "(Maybe ScalarCodecs.Timestamptz)" "created_at" [] (ScalarCodecs.codecs |> Hasura.Scalar.unwrapCodecs |> .codecTimestamptz |> .decoder |> Decode.nullable)


id : SelectionSet (Maybe ScalarCodecs.Uuid) Hasura.Object.Task_rss_min_fields
id =
    Object.selectionForField "(Maybe ScalarCodecs.Uuid)" "id" [] (ScalarCodecs.codecs |> Hasura.Scalar.unwrapCodecs |> .codecUuid |> .decoder |> Decode.nullable)


last_pub_date : SelectionSet (Maybe ScalarCodecs.Timestamptz) Hasura.Object.Task_rss_min_fields
last_pub_date =
    Object.selectionForField "(Maybe ScalarCodecs.Timestamptz)" "last_pub_date" [] (ScalarCodecs.codecs |> Hasura.Scalar.unwrapCodecs |> .codecTimestamptz |> .decoder |> Decode.nullable)


template : SelectionSet (Maybe String) Hasura.Object.Task_rss_min_fields
template =
    Object.selectionForField "(Maybe String)" "template" [] (Decode.string |> Decode.nullable)


updated_at : SelectionSet (Maybe ScalarCodecs.Timestamptz) Hasura.Object.Task_rss_min_fields
updated_at =
    Object.selectionForField "(Maybe ScalarCodecs.Timestamptz)" "updated_at" [] (ScalarCodecs.codecs |> Hasura.Scalar.unwrapCodecs |> .codecTimestamptz |> .decoder |> Decode.nullable)


url : SelectionSet (Maybe String) Hasura.Object.Task_rss_min_fields
url =
    Object.selectionForField "(Maybe String)" "url" [] (Decode.string |> Decode.nullable)


user_id : SelectionSet (Maybe String) Hasura.Object.Task_rss_min_fields
user_id =
    Object.selectionForField "(Maybe String)" "user_id" [] (Decode.string |> Decode.nullable)
