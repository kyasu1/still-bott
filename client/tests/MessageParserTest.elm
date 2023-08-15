module MessageParserTest exposing (suite)

import Expect
import MessageParser
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Twtterのメッセージの文字数をカウントするテスト"
        [ Test.test "半角英数のみ" <|
            \_ ->
                Expect.equal (MessageParser.length "ABCDE GOOD") 10
        , Test.test "日本語のカウント" <|
            \_ ->
                Expect.equal (MessageParser.length "こんにちは") 10
        , Test.test "全角半角混在時のカウント" <|
            \_ ->
                Expect.equal (MessageParser.length "こんにちはElmさん") 17
        , Test.test "スペースを含む文字列のカウント" <|
            \_ ->
                Expect.equal (MessageParser.length "こんにちは Elm さん") 19
        , Test.test "終端に複数のスペースを含む文字列のカウント" <|
            \_ ->
                Expect.equal (MessageParser.length "こんにちは Elm さん  ") 21
        , Test.test "全角スペースを含む文字列のカウント" <|
            \_ ->
                Expect.equal (MessageParser.length "こんにちは\u{3000}Elm\u{3000}さん") 21
        , Test.test "改行を含む文字列のカウント" <|
            \_ ->
                Expect.equal (MessageParser.length "こんにちは\nElm\nさん") 19
        , Test.test "終端に改行を含む文字列のカウント" <|
            \_ ->
                Expect.equal (MessageParser.length "こんにちは\nElm\nさん\n") 20
        , Test.test "URLを含む文字列のカウント" <|
            \_ ->
                Expect.equal (MessageParser.length "こんにちは\nElm\nさん\nhttps://elm-lang.org/") 43
        , Test.test "URLと絵文字と終端に改行を含む文字列のカウント" <|
            \_ ->
                Expect.equal (MessageParser.length "こんにちは\nElmさんhttps://elm-lang.org/🐵🐵\n") 46
        ]
