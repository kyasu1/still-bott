module InteropDefinitions exposing (Flags, FromElm(..), ToElm(..), interop)

import FileValue exposing (File)
import State exposing (State)
import Time
import TsJson.Decode as TsDecode exposing (Decoder)
import TsJson.Encode as TsEncode exposing (Encoder, required)


interop :
    { toElm : Decoder ToElm
    , fromElm : Encoder FromElm
    , flags : Decoder Flags
    }
interop =
    { toElm = toElm
    , fromElm = fromElm
    , flags = flags
    }


type FromElm
    = OpenDialog String
    | CloseDialog String
    | ConvertImage File
    | GetToken


type ToElm
    = AuthenticatedUser User
    | ConvertedImage (Maybe String)
    | GotToken State


type alias User =
    { username : String }


type alias Flags =
    { state : State
    , timestamp : Int
    }


fromElm : Encoder FromElm
fromElm =
    TsEncode.union
        (\vOpenDialog vCloseDialog vFiles vGetToken value ->
            case value of
                OpenDialog string ->
                    vOpenDialog string

                CloseDialog string ->
                    vCloseDialog string

                ConvertImage files ->
                    vFiles files

                GetToken ->
                    vGetToken
        )
        |> TsEncode.variantTagged "OpenDialog"
            (TsEncode.object [ required "id" identity TsEncode.string ])
        |> TsEncode.variantTagged "CloseDialog"
            (TsEncode.object [ required "id" identity TsEncode.string ])
        |> TsEncode.variantTagged "ConvertImage"
            (TsEncode.object
                [ required "file"
                    identity
                    (TsEncode.object
                        [ required "value" .value TsEncode.value
                        , required "name" .name TsEncode.string
                        , required "mime" .mime TsEncode.string
                        , required "size" .size TsEncode.int
                        , required "lastModified" (.lastModified >> Time.posixToMillis) TsEncode.int
                        ]
                    )
                ]
            )
        |> TsEncode.variant0 "GetToken"
        |> TsEncode.buildUnion


toElm : Decoder ToElm
toElm =
    TsDecode.discriminatedUnion "tag"
        [ ( "authenticatedUser"
          , TsDecode.map AuthenticatedUser
                (TsDecode.map User
                    (TsDecode.field "username" TsDecode.string)
                )
          )
        , ( "convertedImage"
          , TsDecode.map ConvertedImage
                (TsDecode.field "image" (TsDecode.maybe TsDecode.string))
          )
        , ( "gotToken"
          , TsDecode.map GotToken State.tsDecoder
          )
        ]


flags : Decoder Flags
flags =
    TsDecode.map2 (\state timestamp -> { state = state, timestamp = timestamp })
        (TsDecode.field "state" State.tsDecoder)
        (TsDecode.field "timestamp" TsDecode.int)
