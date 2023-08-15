use crate::config::CONFIG;
use crate::model::*;
use async_session::{async_trait, Session, SessionStore};
use async_sqlx_session::PostgresSessionStore;
use axum::{
    extract::{
        rejection::TypedHeaderRejectionReason, FromRef, FromRequestParts, Query, State, TypedHeader,
    },
    response::{IntoResponse, Redirect, Response},
    routing::get,
    Json, RequestPartsExt, Router,
};
use axum_extra::extract::{
    cookie::{Cookie, SameSite},
    SignedCookieJar,
};

use crate::twitter::{Data, TwitterUser};
use http::{
    header::{self, SET_COOKIE},
    request::Parts,
    HeaderMap, StatusCode,
};
use oauth2::{
    basic::BasicClient, reqwest::async_http_client, AuthorizationCode, CsrfToken,
    PkceCodeChallenge, PkceCodeVerifier, Scope, TokenResponse,
};
use serde::{Deserialize, Serialize};
use snafu::prelude::*;

/// ERROR

#[derive(Debug, Snafu)]
pub enum Error {
    #[snafu(display("User not found"))]
    UserNotFound,

    FailedIssuJwt {
        source: jsonwebtoken::errors::Error,
    },

    #[snafu(whatever, display("{message}"))]
    Generic {
        message: String,
        #[snafu(source(from(Box<dyn std::error::Error>, Some)))]
        source: Option<Box<dyn std::error::Error>>,
    },
}
/// CONSTANTS
static COOKIE_NAME: &str = "SESSION";
static CODE_VERIFIER: &str = "CODE_VERIFIER";

pub fn create_route() -> Router<crate::state::AppState> {
    Router::new()
        .route("/auth/get_jwt", get(get_jwt))
        .route("/auth/twitter", get(twitter_auth))
        .route("/auth/authorized", get(login_authorized))
        .route("/auth/logout", get(logout))
}

async fn twitter_auth(
    State(client): State<BasicClient>,
    jar: SignedCookieJar,
) -> Result<(SignedCookieJar, Redirect), StatusCode> {
    let (pkce_code_challenge, pkce_code_verifier) = PkceCodeChallenge::new_random_sha256();
    let (auth_url, _csrf_token) = client
        .authorize_url(CsrfToken::new_random)
        .add_scope(Scope::new("users.read".to_string()))
        .add_scope(Scope::new("tweet.read".to_string()))
        .add_scope(Scope::new("tweet.write".to_string()))
        .add_scope(Scope::new("offline.access".to_string()))
        .set_pkce_challenge(pkce_code_challenge)
        .url();

    let cookie = Cookie::build(CODE_VERIFIER, pkce_code_verifier.secret().clone())
        .path("/")
        .secure(true)
        .http_only(true)
        .finish();

    Ok((jar.add(cookie), Redirect::to(auth_url.as_ref())))
}

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct AuthRequest {
    code: String,
    state: String,
}

async fn login_authorized(
    Query(query): Query<AuthRequest>,
    State(store): State<PostgresSessionStore>,
    State(oauth_client): State<BasicClient>,
    jar: SignedCookieJar,
    // ) -> impl IntoResponse {
) -> Result<(SignedCookieJar, HeaderMap, Redirect), StatusCode> {
    // Get an auth token

    let cookie = match jar.get(CODE_VERIFIER) {
        Some(cookie) => cookie,
        None => {
            tracing::error!("Cookie not found");
            return Err(StatusCode::UNAUTHORIZED);
        }
    };

    let pkce_code_verifier = PkceCodeVerifier::new(cookie.value().to_owned());

    // Remove used pkce_code_verifier cookie from jar
    let jar = jar.remove(cookie);

    let token_response = oauth_client
        .exchange_code(AuthorizationCode::new(query.code.clone()))
        .set_pkce_verifier(pkce_code_verifier)
        .request_async(async_http_client)
        .await
        .unwrap();

    tracing::info!("token_response: {:?}", token_response);

    let twitter_user = crate::twitter::get_self(token_response.access_token().secret())
        .await
        .unwrap();

    let token = Token {
        id: twitter_user.id.clone(),
        access_token: token_response.access_token().secret().clone(),
        refresh_token: token_response
            .refresh_token()
            .map(|refresh_token| refresh_token.secret().clone()),
        issued_at: time::OffsetDateTime::now_utc(),
        expires_in: token_response.expires_in(),
    };

    match crate::gq::store_session::store_session(token).await {
        Ok(_) => {
            tracing::debug!("twitter token stored to hasura successfuly")
        }
        Err(err) => {
            tracing::error!("failed to store twitter token to hasura");
            tracing::error!("{:?}", err);
            return Err(StatusCode::UNAUTHORIZED);
        }
    }

    // Create a new session filled with user data and tokens
    let mut session = Session::new();
    session.insert("user", &twitter_user).unwrap();

    // Store session and get corresponding cookie
    let cookie_string: String = store.store_session(session).await.unwrap().unwrap();

    let cookie: Cookie = Cookie::build(COOKIE_NAME, cookie_string)
        .http_only(true)
        .same_site(SameSite::Lax)
        .path("/")
        .finish();

    // Set cookie
    let mut headers = HeaderMap::new();
    headers.insert(SET_COOKIE, cookie.to_string().parse().unwrap());

    Ok((jar, headers, Redirect::to(&CONFIG.backend_endpoint)))

    // let client = reqwest::Client::new();

    // // https://developer.twitter.com/en/docs/twitter-api/users/lookup/api-reference/get-users-me
    // match client
    //     .get("https://api.twitter.com/2/users/me?user.fields=profile_image_url")
    //     .bearer_auth(token_response.access_token().secret())
    //     .send()
    //     .await
    // {
    //     Ok(resp) => {
    //         match resp.status() {
    //             StatusCode::OK => {
    //                 match resp.json::<Data<TwitterUser>>().await {
    //                     Ok(user_data) => {
    //                         let token = Token {
    //                             id: user_data.data.id.clone(),
    //                             access_token: token_response.access_token().secret().clone(),
    //                             refresh_token: token_response
    //                                 .refresh_token()
    //                                 .map(|refresh_token| refresh_token.secret().clone()),
    //                             issued_at: time::OffsetDateTime::now_utc(),
    //                             expires_in: token_response.expires_in(),
    //                         };

    //                         match crate::gq::store_session::store_session(token).await {
    //                             Ok(_) => {
    //                                 tracing::debug!("twitter token stored to hasura successfuly")
    //                             }
    //                             Err(err) => {
    //                                 tracing::error!("failed to store twitter token to hasura");
    //                                 tracing::error!("{:?}", err);
    //                                 return Err(StatusCode::UNAUTHORIZED);
    //                             }
    //                         }

    //                         // Create a new session filled with user data and tokens
    //                         let mut session = Session::new();
    //                         session.insert("user", &user_data.data).unwrap();

    //                         // Store session and get corresponding cookie
    //                         let cookie_string: String =
    //                             store.store_session(session).await.unwrap().unwrap();

    //                         let cookie: Cookie = Cookie::build(COOKIE_NAME, cookie_string)
    //                             .http_only(true)
    //                             .same_site(SameSite::Lax)
    //                             .path("/")
    //                             .finish();

    //                         // Set cookie
    //                         let mut headers = HeaderMap::new();
    //                         headers.insert(SET_COOKIE, cookie.to_string().parse().unwrap());

    //                         Ok((jar, headers, Redirect::to(&CONFIG.backend_endpoint)))
    //                     }
    //                     Err(err) => {
    //                         tracing::error!("Decoding error: {:?}", err);

    //                         Err(StatusCode::BAD_REQUEST)
    //                     }
    //                 }
    //             }
    //             s => {
    //                 tracing::error!("Twitter API responded with the following status {:?}", s);
    //                 Err(s)
    //             }
    //         }
    //     }
    //     Err(err) => {
    //         tracing::error!("error when accessing Twitter api {:?}", err);
    //         Err(StatusCode::UNAUTHORIZED)
    //     }
    // }
}

async fn logout(
    State(store): State<PostgresSessionStore>,
    TypedHeader(cookies): TypedHeader<headers::Cookie>,
) -> impl IntoResponse {
    if let Some(cookie) = cookies.get(COOKIE_NAME) {
        if let Ok(Some(session)) = store.load_session(cookie.to_string()).await {
            if store.destroy_session(session).await.is_ok() {
                Redirect::to("/login")
            } else {
                Redirect::to("/login")
            }
        } else {
            Redirect::to("/login")
        }
    } else {
        Redirect::to("/login")
    }

    // let cookie = cookies.get(COOKIE_NAME).unwrap();
    // let session = match store.load_session(cookie.to_string()).await.unwrap() {
    //     Some(s) => s,
    //     // No session active, just redirect
    //     None => return Redirect::to("/login"),
    // };

    // store.destroy_session(session).await.unwrap();

    // Redirect::to("/login")
}

pub struct AuthRedirect;

impl IntoResponse for AuthRedirect {
    fn into_response(self) -> Response {
        Redirect::temporary("/auth/twitter").into_response()
    }
}

#[async_trait]
impl<S> FromRequestParts<S> for TwitterUser
where
    PostgresSessionStore: FromRef<S>,
    S: Send + Sync,
{
    // If anything goes wrong or no session is found, redirect to the auth page
    type Rejection = AuthRedirect;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let store = PostgresSessionStore::from_ref(state);

        let cookies = parts
            .extract::<TypedHeader<headers::Cookie>>()
            .await
            .map_err(|e| match *e.name() {
                header::COOKIE => match e.reason() {
                    TypedHeaderRejectionReason::Missing => AuthRedirect,
                    _ => panic!("unexpected error getting Cookie header(s): {}", e),
                },
                _ => panic!("unexpected error getting cookies: {}", e),
            })?;
        let session_cookie = cookies.get(COOKIE_NAME).ok_or(AuthRedirect)?;

        let session = store
            .load_session(session_cookie.to_string())
            .await
            .unwrap()
            .ok_or(AuthRedirect)?;

        let user = session.get::<TwitterUser>("user").ok_or(AuthRedirect)?;

        Ok(user)
    }
}

// アクセストークンは2時間（7200秒）有効とされているので、5分間の余裕をもって無効かどうかを判断する
// 仕様変更に備えて、`expire_in`を受け取って判断するように変更するべきかも
fn token_expired(issued_at: time::OffsetDateTime, expires_in: Option<std::time::Duration>) -> bool {
    const MARGIN: i64 = 5 * 60;

    let expires_in = expires_in.unwrap_or(std::time::Duration::from_secs(7200));

    let valid_time_in_secs: i64 = expires_in.as_secs() as i64 - MARGIN;

    let now = time::OffsetDateTime::now_utc();

    tracing::info!(
        "issued_at: {} now: {} difference {}",
        issued_at,
        now,
        now.unix_timestamp() - issued_at.unix_timestamp()
    );

    issued_at.unix_timestamp() + valid_time_in_secs < now.unix_timestamp()
}

// Userテーブルにレコードが存在しない場合
// role == Anonymous && email = None && email_confirmed == false
// Userテーブルにレコードが存在するが、メールアドレスの存在が未確認の場合
// role == Anonymous && email = Some(email) && email_confirmed == false
// メールアドレスを変更した場合
// role == Basic || Premium && email == Some(email) && email_confirmed == false
// メールアドレスは確認済みでアカウントが有効な場合
// role == Bacis || Premium && email == Some(email) && email_confirmed == true
#[derive(Serialize, Debug, Deserialize)]
struct Claims {
    sub: String,
    name: String,
    username: String,
    profile_image_url: Option<String>,
    iat: usize,
    role: Role,
    email: Email,
    #[serde(rename = "https://hasura.io/jwt/claims")]
    hasura_jwt_claims: HasuraJwtClaims,
}

#[derive(Serialize, Debug, Deserialize)]
struct HasuraJwtClaims {
    #[serde(rename = "x-hasura-default-role")]
    x_hasura_default_role: Role,
    #[serde(rename = "x-hasura-allowed-roles")]
    x_hasura_allowed_roles: Vec<Role>,
    #[serde(rename = "x-hasura-user-id")]
    x_hasura_user_id: String,
}

#[derive(Serialize, Debug)]
struct GetTokenResponse {
    token: Option<String>,
}

#[derive(Serialize, Deserialize, Debug)]
#[serde(tag = "t", content = "c")]

enum Email {
    Unregistered,
    Unconfirmed(String),
    Confirmed(String),
}

async fn get_jwt(user: TwitterUser) -> Result<Json<GetTokenResponse>, StatusCode> {
    match crate::gq::get_self::get_self(user.id.clone()).await {
        // `User`テーブルにレコードが存在するかチェックする
        // Oauthで初回にログインした時点ではレコードは存在しない
        // クライアントからメールアドレスを登録した時点でレコードが作成される、メールは未確認状態、ランダムな確認コード6桁を発行
        // メールアドレスの確認が
        Ok(hasura_user) => match hasura_user {
            Some(hasura_user) => {
                if hasura_user.email_confirmed {
                    match issue_jwt_token(
                        user,
                        hasura_user.role,
                        Email::Confirmed(hasura_user.email),
                    ) {
                        Ok(token) => Ok(Json(GetTokenResponse { token: Some(token) })),
                        Err(err) => {
                            tracing::error!(
                                "Failed to encode jsonwebtoken, this should not happen {}",
                                err
                            );
                            Err(StatusCode::INTERNAL_SERVER_ERROR)
                        }
                    }
                } else {
                    match issue_jwt_token(
                        user,
                        hasura_user.role,
                        Email::Unconfirmed(hasura_user.email),
                    ) {
                        Ok(token) => Ok(Json(GetTokenResponse { token: Some(token) })),
                        Err(err) => {
                            tracing::error!(
                                "Failed to encode jsonwebtoken, this should not happen {}",
                                err
                            );
                            Err(StatusCode::INTERNAL_SERVER_ERROR)
                        }
                    }
                }
            }
            None => {
                tracing::info!("No record on User table");
                match issue_jwt_token(user, Role::Anonymous, Email::Unregistered) {
                    Ok(token) => Ok(Json(GetTokenResponse { token: Some(token) })),
                    Err(err) => {
                        tracing::error!(
                            "Failed to encode jsonwebtoken, this should not happen {}",
                            err
                        );
                        Err(StatusCode::INTERNAL_SERVER_ERROR)
                    }
                }
            }
        },

        Err(err) => {
            tracing::error!("get_jwt: get_self: {}", err);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

fn issue_jwt_token(user: TwitterUser, role: Role, email: Email) -> Result<String, Error> {
    let header = jsonwebtoken::Header::new(jsonwebtoken::Algorithm::HS512);

    let hasura_jwt_claims = match role.clone() {
        Role::Anonymous => HasuraJwtClaims {
            x_hasura_default_role: Role::Anonymous,
            x_hasura_allowed_roles: vec![Role::Anonymous],
            x_hasura_user_id: user.id.clone(),
        },
        Role::Basic => HasuraJwtClaims {
            x_hasura_default_role: Role::Basic,
            x_hasura_allowed_roles: vec![Role::Anonymous, Role::Basic],
            x_hasura_user_id: user.id.clone(),
        },
        Role::Premium => HasuraJwtClaims {
            x_hasura_default_role: Role::Premium,
            x_hasura_allowed_roles: vec![Role::Anonymous, Role::Basic, Role::Premium],
            x_hasura_user_id: user.id.clone(),
        },
    };

    let claims = Claims {
        sub: user.id,
        name: user.name,
        username: user.username,
        profile_image_url: user.profile_image_url,
        iat: time::OffsetDateTime::now_utc().unix_timestamp() as usize,
        role,
        email,
        hasura_jwt_claims,
    };

    let secret = crate::config::CONFIG.jwt_secret();
    let key = &jsonwebtoken::EncodingKey::from_secret(secret.as_ref());

    jsonwebtoken::encode(&header, &claims, key).context(FailedIssuJwtSnafu)
}
