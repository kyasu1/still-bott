module Ui.Utils exposing (generateId, onKey)

import Html
import Html.Events as E
import Json.Decode as JD
import Murmur3


generateId : String -> String
generateId name =
    Murmur3.hashString 1578 name |> String.fromInt


onKey : (Int -> msg) -> Html.Attribute msg
onKey toMsg =
    E.on "keyup" (JD.map toMsg E.keyCode)
