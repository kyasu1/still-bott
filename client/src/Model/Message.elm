module Model.Message exposing (Message, MessageId, selection, unwrapId)

import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Hasura.Object
import Hasura.Object.Message
import Model.Media as Media exposing (Media)
import Model.Tag as Tag exposing (Tag)
import Prng.Uuid exposing (Uuid)
import Time exposing (Posix)


type alias Message =
    { id : MessageId
    , text : String
    , tweeted : Bool
    , media : Maybe Media
    , priority : Int
    , createdAt : Posix
    , updatedAt : Posix
    , tag : Maybe Tag
    }


type MessageId
    = MessageId Uuid


unwrapId : MessageId -> Uuid
unwrapId (MessageId uuid) =
    uuid


selection : SelectionSet Message Hasura.Object.Message
selection =
    SelectionSet.succeed Message
        |> SelectionSet.with (Hasura.Object.Message.id |> SelectionSet.map MessageId)
        |> SelectionSet.with Hasura.Object.Message.text
        |> SelectionSet.with Hasura.Object.Message.tweeted
        |> SelectionSet.with (Hasura.Object.Message.media Media.selection)
        |> SelectionSet.with Hasura.Object.Message.priority
        |> SelectionSet.with Hasura.Object.Message.created_at
        |> SelectionSet.with Hasura.Object.Message.updated_at
        |> SelectionSet.with (Hasura.Object.Message.tag Tag.selection)
