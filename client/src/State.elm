module State exposing (State(..), identity, tsDecoder)

import Model.User exposing (User)
import TsJson.Decode as TsDecode exposing (Decoder)


type State
    = Registered User
    | ServerError


tsDecoder : Decoder State
tsDecoder =
    TsDecode.discriminatedUnion "state"
        [ ( "error", TsDecode.succeed ServerError )

        -- , ( "registered"
        --   , TsDecode.map Registered
        --         (TsDecode.field "token" TsDecode.string
        --             |> TsDecode.unknownAndThen
        --                 (\_ ->
        --                     Model.User.userDecoder
        --                 )
        --         )
        --   )
        , ( "registered"
          , TsDecode.succeed (\user -> Registered user)
                |> TsDecode.andMap
                    (TsDecode.field "token"
                        (TsDecode.string
                            |> TsDecode.unknownAndThen Model.User.userDecoder
                         -- (\raw ->
                         --     case JD.decodeString Model.User.userDecoder raw of
                         --         Ok token ->
                         --             JD.succeed token
                         --         Err err ->
                         --             let
                         --                 _ =
                         --                     Debug.log "err " err
                         --             in
                         --             JD.fail "Invalid Token"
                         -- )
                        )
                    )
            -- |> TsDecode.andMap (TsDecode.field "token" (TsDecode.unknownAndThen (\_ -> Model.User.userDecoder)))
          )
        ]



-- [ ( "admin", TsDecode.succeed (\id -> Admin { id = id }) |> Decode.andMap (Decode.field "id" TsDecode.int) )


identity : State -> Maybe User
identity state =
    case state of
        Registered user ->
            Just user

        _ ->
            Nothing
