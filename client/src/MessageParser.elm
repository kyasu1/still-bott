module MessageParser exposing (length)

import Char
import List.Extra as List
import Url


length : String -> Int
length s =
    String.lines s
        |> (\line ->
                List.map tokenizeLine line
           )
        |> List.intersperse 1
        |> List.foldl (+) 0


tokenizeLine : String -> Int
tokenizeLine s =
    String.toList s
        |> List.groupWhile (\a b -> isHankaku a && isHankaku b || (not (isHankaku a) && not (isHankaku b)))
        |> List.map
            (\( a, b ) ->
                let
                    token =
                        String.fromList (a :: b)
                in
                if isHankaku a then
                    case Url.fromString token of
                        Just _ ->
                            23

                        Nothing ->
                            String.length token

                else
                    (String.toList token |> List.length) * 2
            )
        |> List.foldl (+) 0


isHankaku : Char -> Bool
isHankaku c =
    Char.toCode c >= 0x20 && Char.toCode c <= 0x7E
