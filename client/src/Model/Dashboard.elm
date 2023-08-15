module Model.Dashboard exposing (Dashboard, deleteMedia, query)

import Graphql.Operation exposing (RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Hasura.Enum.Role_enum
import Hasura.Object
import Hasura.Object.User
import Model.Media as Media exposing (Media, MediaId)
import Model.Message as Message exposing (Message, MessageId)
import Model.Tag as Tag exposing (Tag, TagId)
import Model.Task as Task exposing (Task)
import Model.TaskRss as TaskRss
import Model.User as User exposing (User, UserId)


type alias Dashboard =
    { userId : UserId
    , email : String
    , active : Bool
    , messages : List Message
    , medias : List Media
    , tasks : List Task
    , rssTasks : List TaskRss.Task
    , tags : List Tag
    }


selection : SelectionSet Dashboard Hasura.Object.User
selection =
    SelectionSet.succeed Dashboard
        |> SelectionSet.with User.userIdSelection
        |> SelectionSet.with Hasura.Object.User.email
        |> SelectionSet.with Hasura.Object.User.active
        |> SelectionSet.with (Hasura.Object.User.messages identity Message.selection)
        |> SelectionSet.with (Hasura.Object.User.medias identity Media.selection)
        |> SelectionSet.with (Hasura.Object.User.tasks_fixed_time identity Task.selection)
        |> SelectionSet.with (Hasura.Object.User.tasks_rss identity TaskRss.selection)
        |> SelectionSet.with (Hasura.Object.User.tag identity Tag.selection)


query : UserId -> SelectionSet (Maybe Dashboard) RootQuery
query id =
    User.queryUser id selection


deleteMedia : MediaId -> Dashboard -> Dashboard
deleteMedia mediaId dashboard =
    List.filter (\media -> media.id /= mediaId) dashboard.medias |> (\medias -> { dashboard | medias = medias })
