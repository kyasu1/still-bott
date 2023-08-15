module Id exposing (Id, decoder, encode, unwrap)

import Json.Decode as JD
import Json.Encode as JE
import Prng.Uuid exposing (Uuid)


type Id a
    = Id Uuid


unwrap : Id a -> Uuid
unwrap (Id uuid) =
    uuid


encode : Id a -> JE.Value
encode (Id s) =
    Prng.Uuid.encode s


decoder : JD.Decoder (Id a)
decoder =
    Prng.Uuid.decoder |> JD.map Id
