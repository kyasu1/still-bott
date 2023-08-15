module Model.User exposing (Email(..), Role(..), User, UserId, queryUser, userDecoder, userIdSelection, userIdToString)

import Email
import Graphql.Operation exposing (RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Hasura.Object
import Hasura.Object.User
import Hasura.Query
import Json.Decode as JD
import Json.Decode.Extra as JD
import Jwt


type UserId
    = UserId String


userIdToString : UserId -> String
userIdToString (UserId id) =
    id


type alias User =
    { id : UserId
    , name : String
    , username : String
    , profileImageUrl : Maybe String
    , role : Role
    , email : Email
    , token : String
    }


type Email
    = Unregistered
    | Unconfirmed Email.Email
    | Confirmed Email.Email


emailDecoder : JD.Decoder Email
emailDecoder =
    JD.field "t" JD.string
        |> JD.andThen
            (\s ->
                case s of
                    "Unregistered" ->
                        JD.succeed Unregistered

                    "Unconfirmed" ->
                        JD.field "c" emailDecoderHelper |> JD.map Unconfirmed

                    "Confirmed" ->
                        JD.field "c" emailDecoderHelper |> JD.map Confirmed

                    _ ->
                        JD.fail "Invalid Email Tag"
            )


emailDecoderHelper : JD.Decoder Email.Email
emailDecoderHelper =
    JD.string
        |> JD.andThen
            (\s ->
                case Email.fromString s of
                    Just email ->
                        JD.succeed email

                    Nothing ->
                        JD.fail "Invalid Email"
            )



-- userDecoder : JD.Decoder User
-- userDecoder =
--     JD.field "token" JD.string
--         |> JD.andThen
--             (\token ->
--                 case
--                     Jwt.decodeToken
--                         (JD.map7 User
--                             (JD.field "sub" JD.string |> JD.map UserId)
--                             (JD.field "name" JD.string)
--                             (JD.field "username" JD.string)
--                             (JD.optionalNullableField "profile_image_url" JD.string)
--                             (JD.field "role" roleDecoder)
--                             (JD.field "email" emailDecoder)
--                             (JD.succeed token)
--                         )
--                         token
--                 of
--                     Ok user ->
--                         JD.succeed user
--                     Err err ->
--                         JD.fail "Failed to decoer user"
--             )


userDecoder : String -> JD.Decoder User
userDecoder token =
    case
        Jwt.decodeToken
            (JD.map7 User
                (JD.field "sub" JD.string |> JD.map UserId)
                (JD.field "name" JD.string)
                (JD.field "username" JD.string)
                (JD.optionalNullableField "profile_image_url" JD.string)
                (JD.field "role" roleDecoder)
                (JD.field "email" emailDecoder)
                (JD.succeed token)
            )
            token
    of
        Ok user ->
            JD.succeed user

        Err err ->
            JD.fail "Failed to decoer user"


queryUser : UserId -> SelectionSet a Hasura.Object.User -> SelectionSet (Maybe a) RootQuery
queryUser (UserId id) selection =
    Hasura.Query.user_by_pk { id = id } selection


userIdSelection : SelectionSet UserId Hasura.Object.User
userIdSelection =
    Hasura.Object.User.id |> SelectionSet.map UserId


type Role
    = Anonymous
    | Basic
    | Premium


roleDecoder : JD.Decoder Role
roleDecoder =
    JD.string
        |> JD.andThen
            (\s ->
                case s of
                    "anonymous" ->
                        JD.succeed Anonymous

                    "basic" ->
                        JD.succeed Basic

                    "premium" ->
                        JD.succeed Premium

                    _ ->
                        JD.fail "Invalid Role"
            )
