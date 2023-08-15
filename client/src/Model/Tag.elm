module Model.Tag exposing (Tag, TagId, asArg, selection, tagSelectInput, toString, unwrapId)

import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Hasura.Object
import Hasura.Object.Tag
import Html exposing (Html, text)
import Html.Attributes as A exposing (class)
import Html.Events as E
import Json.Decode as JD
import Prng.Uuid exposing (Uuid)


type TagId
    = TagId Uuid


unwrapId : TagId -> Uuid
unwrapId (TagId uuid) =
    uuid


type alias Tag =
    { id : TagId
    , name : String
    , description : Maybe String
    }


toString : TagId -> String
toString (TagId id) =
    Prng.Uuid.toString id


selection : SelectionSet Tag Hasura.Object.Tag
selection =
    SelectionSet.succeed Tag
        |> SelectionSet.with (Hasura.Object.Tag.id |> SelectionSet.map TagId)
        |> SelectionSet.with Hasura.Object.Tag.name
        |> SelectionSet.with Hasura.Object.Tag.description


tagSelectInput : Maybe Tag -> List Tag -> (TagId -> msg) -> Html msg
tagSelectInput maybePicked tags onPick =
    if List.length tags > 0 then
        Html.select [ onTagChange onPick ]
            (Html.option [ A.selected (maybePicked == Nothing) ] [ text "タグを選んてください" ]
                :: List.map
                    (\tag ->
                        Html.option
                            [ A.value (toString tag.id)
                            , A.selected (maybePicked == Just tag)
                            ]
                            [ text tag.name ]
                    )
                    tags
            )

    else
        text "タグの登録がありません"


onTagChange : (TagId -> msg) -> Html.Attribute msg
onTagChange tagger =
    E.on "change"
        (E.targetValue
            |> JD.andThen
                (\raw ->
                    case Prng.Uuid.fromString raw of
                        Just uuid ->
                            JD.succeed (tagger (TagId uuid))

                        Nothing ->
                            JD.fail "Invalid TagId"
                )
        )


asArg : Maybe TagId -> OptionalArgument Uuid
asArg maybeTagId =
    case maybeTagId of
        Just (TagId tagId) ->
            Present tagId

        Nothing ->
            Absent
