module Ui.AttributesExtra exposing (includeIf, maybe, none)

import Html
import Html.Attributes as A
import Json.Encode as JE


{-| Represents an attribute with no semantic meaning, useful for conditionals.

This is implemented such that whenever Html.Attributes.Extra.none is encountered
by VirtualDom it will set a meaningless property on the element object itself to
null:

    domNode['Html.Attributes.Extra.none'] = null

It's totally safe and lets us clean up conditional and maybe attributes

-}
none : Html.Attribute msg
none =
    A.property "Html.Attributes.Extra.none" JE.null


{-| Transform a maybe value to an attribute or attach `none`
-}
maybe : (v -> Html.Attribute msg) -> Maybe v -> Html.Attribute msg
maybe toAttr =
    Maybe.map toAttr >> Maybe.withDefault none


{-| conditionally include an attribute. Useful for CSS classes generated with
`UniqueClass`!
-}
includeIf : Bool -> Html.Attribute msg -> Html.Attribute msg
includeIf cond attr =
    if cond then
        attr

    else
        none
