module Model.TaskRss exposing (Task, TaskId, asArg, selection, unwrapId)

import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Hasura.Object
import Hasura.Object.Task_rss
import LocalTime exposing (LocalTime)
import Prng.Uuid exposing (Uuid)
import Time
import Url exposing (Url)


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
    , lastPubDate : Maybe Time.Posix
    , url : Url
    , tempalte : Maybe String
    , random : Bool
    , enabled : Bool
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


selection : SelectionSet Task Hasura.Object.Task_rss
selection =
    SelectionSet.succeed Task
        |> SelectionSet.with (Hasura.Object.Task_rss.id |> SelectionSet.map TaskId)
        |> SelectionSet.with Hasura.Object.Task_rss.tweet_at
        |> SelectionSet.with Hasura.Object.Task_rss.sun
        |> SelectionSet.with Hasura.Object.Task_rss.mon
        |> SelectionSet.with Hasura.Object.Task_rss.tue
        |> SelectionSet.with Hasura.Object.Task_rss.wed
        |> SelectionSet.with Hasura.Object.Task_rss.thu
        |> SelectionSet.with Hasura.Object.Task_rss.fri
        |> SelectionSet.with Hasura.Object.Task_rss.sat
        |> SelectionSet.with Hasura.Object.Task_rss.last_pub_date
        |> SelectionSet.with (urlSelection Hasura.Object.Task_rss.url)
        |> SelectionSet.with Hasura.Object.Task_rss.template
        |> SelectionSet.with Hasura.Object.Task_rss.random
        |> SelectionSet.with Hasura.Object.Task_rss.enabled
        |> SelectionSet.with Hasura.Object.Task_rss.created_at
        |> SelectionSet.with Hasura.Object.Task_rss.updated_at


asArg : Maybe TaskId -> OptionalArgument Uuid
asArg maybeTaskId =
    case maybeTaskId of
        Just (TaskId id) ->
            Present id

        Nothing ->
            Absent


urlSelection : SelectionSet String scope -> SelectionSet Url scope
urlSelection =
    SelectionSet.mapOrFail
        (\s ->
            case Url.fromString s of
                Just url ->
                    Ok url

                Nothing ->
                    Err "Invalid URL String "
        )
