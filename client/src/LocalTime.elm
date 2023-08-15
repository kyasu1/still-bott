module LocalTime exposing (Format(..), LocalTime, decoder, format, parser, toString)

import Json.Decode as JD


type LocalTime
    = LocalTime Int Int Int


type Format
    = Base12
    | Base24


decoder : JD.Decoder LocalTime
decoder =
    JD.string
        |> JD.andThen
            (\s ->
                case parser s of
                    Ok time ->
                        JD.succeed time

                    Err err ->
                        JD.fail err
            )


parser : String -> Result String LocalTime
parser s =
    case String.split ":" s of
        [ hour, miniute, second ] ->
            Result.map3 LocalTime
                (baseNParser 24 hour)
                (baseNParser 60 miniute)
                (baseNParser 60 second)

        [ hour, miniute ] ->
            Result.map3 LocalTime
                (baseNParser 24 hour)
                (baseNParser 60 miniute)
                (Ok 0)

        _ ->
            Err "Invalid Time Format"


baseNParser : Int -> String -> Result String Int
baseNParser base hour =
    case String.toInt hour of
        Just h ->
            if h >= 0 && h < base then
                Ok h

            else
                Err "Out of range "

        Nothing ->
            Err "Invalid hour"


toString : LocalTime -> String
toString =
    format Base24


format : Format -> LocalTime -> String
format f (LocalTime h m s) =
    case f of
        Base12 ->
            let
                ( hh, ampm ) =
                    if h // 12 == 0 then
                        ( h, "am" )

                    else
                        ( h - 12, "pm" )
            in
            String.concat
                [ String.fromInt hh |> String.padLeft 2 '0'
                , ":"
                , String.fromInt m |> String.padLeft 2 '0'
                , ":"
                , String.fromInt s |> String.padLeft 2 '0'
                , ampm
                ]

        Base24 ->
            String.concat
                [ String.fromInt h |> String.padLeft 2 '0'
                , ":"
                , String.fromInt m |> String.padLeft 2 '0'
                , ":"
                , String.fromInt s |> String.padLeft 2 '0'
                ]
