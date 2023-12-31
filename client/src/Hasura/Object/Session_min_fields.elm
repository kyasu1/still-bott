-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Hasura.Object.Session_min_fields exposing (..)

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


access_token : SelectionSet (Maybe String) Hasura.Object.Session_min_fields
access_token =
    Object.selectionForField "(Maybe String)" "access_token" [] (Decode.string |> Decode.nullable)


expires_in : SelectionSet (Maybe Int) Hasura.Object.Session_min_fields
expires_in =
    Object.selectionForField "(Maybe Int)" "expires_in" [] (Decode.int |> Decode.nullable)


id : SelectionSet (Maybe String) Hasura.Object.Session_min_fields
id =
    Object.selectionForField "(Maybe String)" "id" [] (Decode.string |> Decode.nullable)


issued_at : SelectionSet (Maybe ScalarCodecs.Timestamptz) Hasura.Object.Session_min_fields
issued_at =
    Object.selectionForField "(Maybe ScalarCodecs.Timestamptz)" "issued_at" [] (ScalarCodecs.codecs |> Hasura.Scalar.unwrapCodecs |> .codecTimestamptz |> .decoder |> Decode.nullable)


name : SelectionSet (Maybe String) Hasura.Object.Session_min_fields
name =
    Object.selectionForField "(Maybe String)" "name" [] (Decode.string |> Decode.nullable)


refresh_token : SelectionSet (Maybe String) Hasura.Object.Session_min_fields
refresh_token =
    Object.selectionForField "(Maybe String)" "refresh_token" [] (Decode.string |> Decode.nullable)


user_name : SelectionSet (Maybe String) Hasura.Object.Session_min_fields
user_name =
    Object.selectionForField "(Maybe String)" "user_name" [] (Decode.string |> Decode.nullable)
