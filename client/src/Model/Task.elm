module Model.Task exposing (Task, TaskId, asArg, selection, unwrapId)

import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Hasura.Object
import Hasura.Object.Task_fixed_time
import LocalTime exposing (LocalTime)
import Model.Tag as Tag exposing (Tag)
import Prng.Uuid exposing (Uuid)
import Time


type TaskId
    = TaskId Uuid


unwrapId : TaskId -> Uuid
unwrapId (TaskId uuid) =
    uuid



--


type alias Task =
    { id : TaskId
    , tweetAt : LocalTime
    , sun : Bool
    , mon : Bool
    , tue : Bool
    , wed : Bool
    , thu : Bool
    , fri : Bool
    , sat : Bool
    , random : Bool
    , enabled : Bool
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    , tag : Maybe Tag
    }


selection : SelectionSet Task Hasura.Object.Task_fixed_time
selection =
    SelectionSet.succeed Task
        |> SelectionSet.with (Hasura.Object.Task_fixed_time.id |> SelectionSet.map TaskId)
        |> SelectionSet.with Hasura.Object.Task_fixed_time.tweet_at
        |> SelectionSet.with Hasura.Object.Task_fixed_time.sun
        |> SelectionSet.with Hasura.Object.Task_fixed_time.mon
        |> SelectionSet.with Hasura.Object.Task_fixed_time.tue
        |> SelectionSet.with Hasura.Object.Task_fixed_time.wed
        |> SelectionSet.with Hasura.Object.Task_fixed_time.thu
        |> SelectionSet.with Hasura.Object.Task_fixed_time.fri
        |> SelectionSet.with Hasura.Object.Task_fixed_time.sat
        |> SelectionSet.with Hasura.Object.Task_fixed_time.random
        |> SelectionSet.with Hasura.Object.Task_fixed_time.enabled
        |> SelectionSet.with Hasura.Object.Task_fixed_time.created_at
        |> SelectionSet.with Hasura.Object.Task_fixed_time.updated_at
        |> SelectionSet.with (Hasura.Object.Task_fixed_time.tag Tag.selection)


asArg : Maybe TaskId -> OptionalArgument Uuid
asArg maybeTaskId =
    case maybeTaskId of
        Just (TaskId taskId) ->
            Present taskId

        Nothing ->
            Absent
