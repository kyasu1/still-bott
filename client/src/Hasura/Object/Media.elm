-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Hasura.Object.Media exposing (..)

import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Hasura.Enum.Message_select_column
import Hasura.InputObject
import Hasura.Interface
import Hasura.Object
import Hasura.Scalar
import Hasura.Union
import Json.Decode as Decode
import ScalarCodecs


id : SelectionSet ScalarCodecs.Uuid Hasura.Object.Media
id =
    Object.selectionForField "ScalarCodecs.Uuid" "id" [] (ScalarCodecs.codecs |> Hasura.Scalar.unwrapCodecs |> .codecUuid |> .decoder)


type alias MessagesOptionalArguments =
    { distinct_on : OptionalArgument (List Hasura.Enum.Message_select_column.Message_select_column)
    , limit : OptionalArgument Int
    , offset : OptionalArgument Int
    , order_by : OptionalArgument (List Hasura.InputObject.Message_order_by)
    , where_ : OptionalArgument Hasura.InputObject.Message_bool_exp
    }


{-| An array relationship

  - distinct\_on - distinct select on columns
  - limit - limit the number of rows returned
  - offset - skip the first n rows. Use only with order\_by
  - order\_by - sort the rows by one or more columns
  - where\_ - filter the rows returned

-}
messages :
    (MessagesOptionalArguments -> MessagesOptionalArguments)
    -> SelectionSet decodesTo Hasura.Object.Message
    -> SelectionSet (List decodesTo) Hasura.Object.Media
messages fillInOptionals____ object____ =
    let
        filledInOptionals____ =
            fillInOptionals____ { distinct_on = Absent, limit = Absent, offset = Absent, order_by = Absent, where_ = Absent }

        optionalArgs____ =
            [ Argument.optional "distinct_on" filledInOptionals____.distinct_on (Encode.enum Hasura.Enum.Message_select_column.toString |> Encode.list), Argument.optional "limit" filledInOptionals____.limit Encode.int, Argument.optional "offset" filledInOptionals____.offset Encode.int, Argument.optional "order_by" filledInOptionals____.order_by (Hasura.InputObject.encodeMessage_order_by |> Encode.list), Argument.optional "where" filledInOptionals____.where_ Hasura.InputObject.encodeMessage_bool_exp ]
                |> List.filterMap Basics.identity
    in
    Object.selectionForCompositeField "messages" optionalArgs____ object____ (Basics.identity >> Decode.list)


type alias MessagesAggregateOptionalArguments =
    { distinct_on : OptionalArgument (List Hasura.Enum.Message_select_column.Message_select_column)
    , limit : OptionalArgument Int
    , offset : OptionalArgument Int
    , order_by : OptionalArgument (List Hasura.InputObject.Message_order_by)
    , where_ : OptionalArgument Hasura.InputObject.Message_bool_exp
    }


{-| An aggregate relationship

  - distinct\_on - distinct select on columns
  - limit - limit the number of rows returned
  - offset - skip the first n rows. Use only with order\_by
  - order\_by - sort the rows by one or more columns
  - where\_ - filter the rows returned

-}
messages_aggregate :
    (MessagesAggregateOptionalArguments -> MessagesAggregateOptionalArguments)
    -> SelectionSet decodesTo Hasura.Object.Message_aggregate
    -> SelectionSet decodesTo Hasura.Object.Media
messages_aggregate fillInOptionals____ object____ =
    let
        filledInOptionals____ =
            fillInOptionals____ { distinct_on = Absent, limit = Absent, offset = Absent, order_by = Absent, where_ = Absent }

        optionalArgs____ =
            [ Argument.optional "distinct_on" filledInOptionals____.distinct_on (Encode.enum Hasura.Enum.Message_select_column.toString |> Encode.list), Argument.optional "limit" filledInOptionals____.limit Encode.int, Argument.optional "offset" filledInOptionals____.offset Encode.int, Argument.optional "order_by" filledInOptionals____.order_by (Hasura.InputObject.encodeMessage_order_by |> Encode.list), Argument.optional "where" filledInOptionals____.where_ Hasura.InputObject.encodeMessage_bool_exp ]
                |> List.filterMap Basics.identity
    in
    Object.selectionForCompositeField "messages_aggregate" optionalArgs____ object____ Basics.identity


thumbnail : SelectionSet String Hasura.Object.Media
thumbnail =
    Object.selectionForField "String" "thumbnail" [] Decode.string


uploaded_at : SelectionSet ScalarCodecs.Timestamptz Hasura.Object.Media
uploaded_at =
    Object.selectionForField "ScalarCodecs.Timestamptz" "uploaded_at" [] (ScalarCodecs.codecs |> Hasura.Scalar.unwrapCodecs |> .codecTimestamptz |> .decoder)


user_id : SelectionSet String Hasura.Object.Media
user_id =
    Object.selectionForField "String" "user_id" [] Decode.string