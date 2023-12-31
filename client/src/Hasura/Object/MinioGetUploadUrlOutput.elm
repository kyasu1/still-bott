-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Hasura.Object.MinioGetUploadUrlOutput exposing (..)

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


mediaId : SelectionSet ScalarCodecs.Uuid Hasura.Object.MinioGetUploadUrlOutput
mediaId =
    Object.selectionForField "ScalarCodecs.Uuid" "mediaId" [] (ScalarCodecs.codecs |> Hasura.Scalar.unwrapCodecs |> .codecUuid |> .decoder)


url : SelectionSet String Hasura.Object.MinioGetUploadUrlOutput
url =
    Object.selectionForField "String" "url" [] Decode.string
