-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Hasura.VerifyScalarCodecs exposing (..)

{-
   This file is intended to be used to ensure that custom scalar decoder
   files are valid. It is compiled using `elm make` by the CLI.
-}

import Hasura.Scalar
import ScalarCodecs


verify : Hasura.Scalar.Codecs ScalarCodecs.Time ScalarCodecs.Timestamptz ScalarCodecs.Uuid
verify =
    ScalarCodecs.codecs
