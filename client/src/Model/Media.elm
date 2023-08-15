module Model.Media exposing (Media, MediaId, UploadUrl, asArg, decoder, deleteMedia, getPresignPostUrl, saveMedia, selection, unwrapId)

import Graphql.Operation exposing (RootMutation)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Hasura.Mutation
import Hasura.Object
import Hasura.Object.DeleteImageOutput
import Hasura.Object.Media
import Hasura.Object.MinioGetUploadUrlOutput
import Hasura.Object.SaveMediaOutput
import Json.Decode as JD
import Prng.Uuid exposing (Uuid)
import Time exposing (Posix)


type MediaId
    = MediaId Uuid


unwrapId : MediaId -> Uuid
unwrapId (MediaId uuid) =
    uuid


type alias Media =
    { id : MediaId
    , userId : String
    , thumbnail : String
    , uploadedAt : Posix
    }


selection : SelectionSet Media Hasura.Object.Media
selection =
    SelectionSet.succeed Media
        |> SelectionSet.with (Hasura.Object.Media.id |> SelectionSet.map MediaId)
        |> SelectionSet.with Hasura.Object.Media.user_id
        |> SelectionSet.with Hasura.Object.Media.thumbnail
        |> SelectionSet.with Hasura.Object.Media.uploaded_at


decoder : JD.Decoder Media
decoder =
    JD.map4 Media
        (JD.field "id" (Prng.Uuid.decoder |> JD.map MediaId))
        (JD.field "userId" JD.string)
        (JD.field "thumbnail" JD.string)
        (JD.field "uploadedAt" (JD.int |> JD.map Time.millisToPosix))


asArg : Maybe MediaId -> OptionalArgument Uuid
asArg maybeMediaId =
    case maybeMediaId of
        Just (MediaId tagId) ->
            Present tagId

        Nothing ->
            Absent


type alias UploadUrl =
    { url : String
    , mediaId : MediaId
    }


getPresignPostUrl : SelectionSet UploadUrl RootMutation
getPresignPostUrl =
    { dummy = True }
        |> (\args ->
                Hasura.Mutation.minioGetUploadUrl { args = args }
                    (SelectionSet.map2 UploadUrl
                        Hasura.Object.MinioGetUploadUrlOutput.url
                        (SelectionSet.map MediaId Hasura.Object.MinioGetUploadUrlOutput.mediaId)
                    )
           )


saveMedia : MediaId -> SelectionSet Media RootMutation
saveMedia (MediaId uuid) =
    { mediaId = uuid }
        |> (\args ->
                Hasura.Mutation.saveMedia { args = args }
                    (SelectionSet.map4 Media
                        (SelectionSet.map MediaId Hasura.Object.SaveMediaOutput.id)
                        Hasura.Object.SaveMediaOutput.userId
                        Hasura.Object.SaveMediaOutput.thumbnail
                        Hasura.Object.SaveMediaOutput.uploadedAt
                    )
           )


deleteMedia : MediaId -> SelectionSet MediaId RootMutation
deleteMedia (MediaId uuid) =
    { mediaId = uuid }
        |> (\args -> Hasura.Mutation.deleteImage { args = args } (SelectionSet.map MediaId Hasura.Object.DeleteImageOutput.mediaId))
