module Form.Decoder.Extra exposing (..)

import Date exposing (Date)
import Form.Decoder exposing (..)
import List.Extra
import String


type FormError
    = TooShort Int
    | TooLong Int
    | NotEmpty
    | InvalidInteger
    | InvalidChar Char
    | InvalidDate
    | Custom (List String)
    | Composite (List String)


toString : FormError -> String
toString v =
    case v of
        TooShort minLength ->
            String.fromInt minLength ++ "文字以上で入力してください"

        TooLong maxLength ->
            String.fromInt maxLength ++ "文字以下で入力してください"

        NotEmpty ->
            "入力してください"

        InvalidInteger ->
            "数字で入力してください"

        InvalidChar c ->
            "不正な文字が含まれています: " ++ String.fromChar c

        InvalidDate ->
            "不正な日付です"

        Custom s ->
            String.concat s

        Composite s ->
            String.concat s


errorMessage : Bool -> Decoder input FormError a -> input -> Maybe String
errorMessage submitting decoder input =
    if submitting then
        errors decoder input |> List.head |> Maybe.map toString

    else
        Nothing



--


succeed : a -> Decoder input never a
succeed a =
    custom <| \_ -> Ok a


required : err -> Decoder (Maybe input) err input
required err =
    custom <|
        \maybeValue ->
            case maybeValue of
                Just value ->
                    Ok value

                Nothing ->
                    Err [ err ]


maybe : Decoder String err a -> Decoder String err (Maybe a)
maybe d =
    custom <|
        \s ->
            if s == "" then
                Ok Nothing

            else
                run d s |> Result.map Just


maybeIf : (i -> Bool) -> Decoder i err a -> Decoder i err (Maybe a)
maybeIf f d =
    custom <|
        \s ->
            if f s then
                run d s |> Result.map Just

            else
                Ok Nothing


numeric : err -> Validator String err
numeric err =
    custom <|
        \s ->
            if String.filter (not << Char.isDigit) s /= "" then
                Err [ err ]

            else
                Ok ()


alpha : err -> Validator String err
alpha err =
    custom <|
        \s ->
            if String.filter (\c -> Char.isAlpha c |> not) s /= "" then
                Err [ err ]

            else
                Ok ()


alphaNum : err -> Validator String err
alphaNum err =
    custom <|
        \s ->
            if String.filter (\c -> Char.isAlphaNum c |> not) s /= "" then
                Err [ err ]

            else
                Ok ()


length : err -> Int -> Validator String err
length err bound =
    custom <|
        \s ->
            if String.length s == bound then
                Ok ()

            else
                Err [ err ]


date : Decoder String FormError Date
date =
    custom <|
        \s ->
            Date.fromIsoString s
                |> Result.mapError (\_ -> [ InvalidDate ])


parseField : Int -> Decoder String FormError String
parseField maxLength =
    custom <|
        \s ->
            let
                trimmed =
                    String.trim s
            in
            if String.isEmpty trimmed then
                Err [ NotEmpty ]

            else if String.length trimmed > maxLength then
                Err [ TooLong maxLength ]

            else
                case String.toList trimmed |> List.Extra.find checkMenzeiAllowedCode of
                    Just char ->
                        Err [ InvalidChar char ]

                    Nothing ->
                        Ok trimmed


checkMenzeiAllowedCode : Char -> Bool
checkMenzeiAllowedCode c =
    if c == '\t' || c == '\n' || c == '\u{000D}' then
        True

    else
        List.map (\( lower, upper ) -> c >= lower && c <= upper) validRanges |> List.all (\e -> e == True)


validRanges : List ( Char, Char )
validRanges =
    [ ( ' ', '~' )
    , ( '\u{3040}', 'ゟ' )
    , ( '゠', 'ヿ' )
    , ( '一', '\u{9FFF}' )
    , ( '豈', '\u{FAFF}' )
    , ( '\u{3000}', '〿' )
    , ( '\u{FF00}', '･' )
    , ( 'ﾠ', '\u{FFEF}' )
    , ( '\u{00A0}', 'ÿ' )
    , ( '←', '⇿' )
    , ( '\u{2000}', '\u{206F}' )
    , ( '─', '╿' )
    , ( '■', '◿' )
    , ( 'Ͱ', 'Ͽ' )
    , ( 'Ѐ', 'ӿ' )
    , ( '∀', '⋿' )
    , ( '⅐', '\u{218F}' )
    , ( '①', '⓿' )
    , ( '㈀', '\u{32FF}' )
    , ( '㌀', '㏿' )
    ]



-- parseNumericField : Int -> String -> Result FormError String
-- parseNumericField maxLength s =
--     let
--         trimmed =
--             String.trim s
--     in
--     if String.isEmpty trimmed then
--         Err NotEmpty
--     else if String.length trimmed > maxLength then
--         Err (TooLong maxLength)
--     else
--         case String.toList trimmed |> List.Extra.find (not << Char.isDigit) of
--             Just char ->
--                 Err (InvalidChar char)
--             Nothing ->
--                 Ok trimmed


parseNumericField : Int -> Decoder String FormError String
parseNumericField maxLength =
    custom <|
        \s ->
            let
                trimmed =
                    String.trim s
            in
            if String.isEmpty trimmed then
                Err [ NotEmpty ]

            else if String.length trimmed > maxLength then
                Err [ TooLong maxLength ]

            else
                case String.toList trimmed |> List.Extra.find (not << Char.isDigit) of
                    Just char ->
                        Err [ InvalidChar char ]

                    Nothing ->
                        Ok trimmed



{- -}


parseAlphabetField : Int -> Decoder String FormError String
parseAlphabetField maxLength =
    custom <|
        \s ->
            let
                trimmed =
                    String.trim s
            in
            if String.isEmpty trimmed then
                Err [ NotEmpty ]

            else if String.length trimmed > maxLength then
                Err [ TooLong maxLength ]

            else
                case
                    String.toList (String.replace " " "" trimmed)
                        |> List.Extra.find (not << Char.isAlpha)
                of
                    Just char ->
                        Err [ InvalidChar char ]

                    Nothing ->
                        Ok trimmed



{- -}


parseAlphaNumericField : Int -> Decoder String FormError String
parseAlphaNumericField maxLength =
    custom <|
        \s ->
            let
                trimmed =
                    String.trim s
            in
            if String.isEmpty trimmed then
                Err [ NotEmpty ]

            else if String.length trimmed > maxLength then
                Err [ TooLong maxLength ]

            else
                case
                    String.toList trimmed
                        |> List.Extra.find (not << Char.isAlphaNum)
                of
                    Just char ->
                        Err [ InvalidChar char ]

                    Nothing ->
                        Ok trimmed
