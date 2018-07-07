module PlayHTTP exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Http
import Debug
import Json.Decode as JSONDecode exposing (Decoder)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)


-- MODEL


type alias Model =
    {}



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "page-content" ]
        [ h1 [] [ text "elm-http-request" ]
        , button [ onClick Call_getStringRequest ] [ text "Call_getStringRequest" ]
        , br [] []
        , button [ onClick Call_getStringRequest2 ] [ text "Call_getStringRequest2" ]
        , br [] []
        , button [ onClick Call_getStringRequest3 ] [ text "Call_getStringRequest3" ]
        , br [] []
        , button [ onClick Call_FailGetStringRequest ] [ text "Call_FailGetStringRequest" ]
        , br [] []
        , button [ onClick Call_GetUser ] [ text "Call_GetUser" ]
        ]



-- Update


type Msg
    = NoOp
    | Call_getStringRequest
    | Call_getStringRequest2
    | Call_getStringRequest3
    | Handle_getStringRequest (Result Http.Error String)
    | Call_FailGetStringRequest
    | Handle_FailGetStringRequest (Result Http.Error String)
    | Call_GetUser
    | Handle_GetUser (Result Http.Error User)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        -- call the getStringRequest command, which will pass the request to the Runtime
        -- model remains unchanged
        Call_getStringRequest ->
            model ! [ getStringRequest ]

        Call_getStringRequest2 ->
            model ! [ getStringRequest2 ]

        Call_getStringRequest3 ->
            model ! [ getStringRequest3 ]

        -- Http.send will invoke this Msg passing the response or error
        Handle_getStringRequest (Ok result) ->
            model ! []

        Handle_getStringRequest (Err errorMessage) ->
            -- log the error message to the console
            Debug.log (toString errorMessage) model ! []

        Call_FailGetStringRequest ->
            model ! [ failGetStringRequest ]

        Handle_FailGetStringRequest (Ok result) ->
            model ! []

        Handle_FailGetStringRequest (Err errorMessage) ->
            -- log the error message to the console
            Debug.log (httpErrorToString errorMessage) model ! []

        Call_GetUser ->
            model ! [ getUser ]

        Handle_GetUser (Ok result) ->
            model ! []

        Handle_GetUser (Err errorMessage) ->
            Debug.log (httpErrorToString errorMessage) model ! []



-- HTTP Requests


serverURL : String
serverURL =
    "http://localhost:3000"


getStringRequest : Cmd Msg
getStringRequest =
    let
        request =
            Http.getString serverURL
    in
        Http.send Handle_getStringRequest request


getStringRequest2 : Cmd Msg
getStringRequest2 =
    {-
       Similar request to getStringRequest but uses the Http.get function
       Http.get expects a decoder, in this case it's a string, so we use the "string" helper.

       An important thing to be aware with Http.get is that unlike getString, it expects a JSON response.
       If the response does not match a decoder, Elm will return an Http.BadPayload error.

    -}
    let
        -- The response must be a quoted string `"foo"` for example.
        -- If the string is not quoted, the decoder fails since it's not JSON.
        decoder =
            JSONDecode.string

        request =
            Http.get serverURL decoder
    in
        Http.send Handle_getStringRequest request


getStringRequest3 : Cmd Msg
getStringRequest3 =
    {-
       same request as getStringRequest but uses the lower level Http.request function
       to build the http request.

       Here we went back to expecting a string.
    -}
    let
        request =
            Http.request
                { method = "GET"
                , headers = []
                , url = serverURL
                , body = Http.emptyBody
                , expect = Http.expectString
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send Handle_getStringRequest request


failGetStringRequest : Cmd Msg
failGetStringRequest =
    {- similar to all the other requests, but this time it will fail -}
    let
        decoder =
            JSONDecode.string

        request =
            Http.request
                { method = "GET"
                , headers = []
                , url = serverURL ++ "/fail_500"
                , body = Http.emptyBody
                , expect = Http.expectJson decoder
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send Handle_FailGetStringRequest request


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.Timeout ->
            "Timeout!"

        Http.NetworkError ->
            "Network Error"

        Http.BadPayload status message ->
            "status: " ++ (toString status) ++ " " ++ (toString message)

        Http.BadStatus status ->
            "status: " ++ (toString status)

        Http.BadUrl status ->
            "status: " ++ (toString status)


type alias User =
    { name : String
    , age : Int
    }


userDecoder : Decoder User
userDecoder =
    decode User
        |> required "name" JSONDecode.string
        |> required "age" JSONDecode.int


getUser : Cmd Msg
getUser =
    let
        userURL =
            serverURL ++ "/user/1"

        request =
            Http.get userURL userDecoder
    in
        Http.send Handle_GetUser request



-- MAIN


initialModel =
    {}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


init =
    ( initialModel, Cmd.none )


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
