use crate::model::Token;
use oauth2::{basic::BasicClient, reqwest::async_http_client, RefreshToken, TokenResponse};
use reqwest::multipart;
use serde::{Deserialize, Serialize};
use snafu::prelude::*;

#[derive(Debug, Snafu)]
pub enum Error {
    FailedRefreshToken {
        source: oauth2::basic::BasicRequestTokenError<oauth2::reqwest::AsyncHttpClientError>,
    },
    DecodeTwitterResponse {
        source: reqwest::Error,
    },
    TwitterNetworkError {
        source: reqwest::Error,
    },
    TwitterError {
        error: TwitterError,
    },
    UserNotFound,
    UploadMedia,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct TwitterError {
    title: String,
    detail: String,
    #[serde(rename = "type")]
    type_: String,
    status: usize,
}

pub async fn refresh_token(
    oauth_client: BasicClient,
    id: String,
    refresh_token: String,
) -> Result<Token, Error> {
    let resp = oauth_client
        .exchange_refresh_token(&RefreshToken::new(refresh_token))
        .request_async(async_http_client)
        .await
        .context(FailedRefreshTokenSnafu)?;

    let new_token = crate::model::Token {
        id,
        access_token: resp.access_token().secret().to_string(),
        refresh_token: resp.refresh_token().map(|r| r.secret().to_string()),
        issued_at: time::OffsetDateTime::now_utc(),
        expires_in: resp.expires_in(),
    };

    Ok(new_token)
}
//

// User data
#[derive(Debug, Serialize, Deserialize)]
pub struct Data<T> {
    pub data: T,
}

#[derive(Deserialize, Serialize, Debug)]
pub struct TweetsResponse {
    pub id: String,
    pub text: String,
}

pub async fn send_tweet_impl(token: Token, json: serde_json::Value) -> Result<String, Error> {
    let client = reqwest::Client::new();

    let resp = client
        .post("https://api.twitter.com/2/tweets")
        .json(&json)
        .bearer_auth(token.access_token)
        .send()
        .await
        .context(TwitterNetworkSnafu)?;

    if resp.status().is_success() {
        resp.json::<Data<TweetsResponse>>()
            .await
            .context(DecodeTwitterResponseSnafu)
            .map(|data| data.data.id)
    } else {
        let error = resp
            .json::<TwitterError>()
            .await
            .context(DecodeTwitterResponseSnafu)?;

        Err(Error::TwitterError { error })
    }
}

// Media Upload
#[derive(Serialize, Deserialize, Debug)]
pub struct UploadMediaResponse {
    media_id: u64,
    media_id_string: String,
    size: u64,
    expires_after_secs: u64,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct UploadMediaErrors {
    errors: Vec<UploadMediaError>,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct UploadMediaError {
    message: String,
    code: usize,
}

#[derive(oauth::Request)]
struct UploadMedia {}

pub async fn twitter_v1_media_upload(
    user_id: String,
    media_id: uuid::Uuid,
    bucket: s3::Bucket,
) -> Result<String, Error> {
    let object = bucket.get_object(media_id.to_string()).await.unwrap();

    let bytes: Vec<u8> = object.bytes().to_vec();

    let file = multipart::Part::bytes(bytes)
        .file_name(media_id.to_string())
        .mime_str("image/jpeg")
        .unwrap();

    let form = reqwest::multipart::Form::new()
        .part("media", file)
        .part("additional_owners", multipart::Part::text(user_id.clone()));

    let uri = "https://upload.twitter.com/1.1/media/upload.json";
    let params = UploadMedia {};

    let token = crate::config::CONFIG.oauth_1_token();
    let auth_header = oauth::post(uri, &params, &token, oauth::HMAC_SHA1);

    let client = reqwest::Client::new();
    let resp = client
        .post(uri)
        .header("Authorization", auth_header)
        .multipart(form)
        .send()
        .await
        .context(TwitterNetworkSnafu)?;

    if resp.status().is_success() {
        let json = resp
            .json::<UploadMediaResponse>()
            .await
            .context(DecodeTwitterResponseSnafu)?;

        Ok(json.media_id_string)
    } else {
        let errors = resp
            .json::<UploadMediaErrors>()
            .await
            .context(DecodeTwitterResponseSnafu)?;

        tracing::error!("Failed to upload Twitter medias {:?}", errors);
        Err(Error::UploadMedia)
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TwitterUser {
    pub id: String,
    pub name: String,
    pub username: String,
    pub profile_image_url: Option<String>,
}

pub async fn get_self(access_token: &String) -> Result<TwitterUser, Error> {
    let client = reqwest::Client::new();

    // https://developer.twitter.com/en/docs/twitter-api/users/lookup/api-reference/get-users-me
    let resp = client
        .get("https://api.twitter.com/2/users/me?user.fields=profile_image_url")
        .bearer_auth(access_token)
        .send()
        .await
        .context(TwitterNetworkSnafu)?;

    if resp.status().is_success() {
        resp.json::<Data<TwitterUser>>()
            .await
            .map(|data| data.data)
            .context(DecodeTwitterResponseSnafu)
    } else {
        Err(Error::UserNotFound)
    }
}
#[tokio::test]
async fn test_twitter_v1_media_upload() {
    use std::str::FromStr;

    let id = uuid::Uuid::from_str("a3893652-d741-463d-a4be-b9dafb5a0d96").unwrap();
    let user_id = String::from("751625934894084097");

    let bucket = crate::minio::get_or_create_bucket(&user_id)
        .await
        .context(crate::error::MinioSnafu)
        .unwrap();

    twitter_v1_media_upload(user_id, id, bucket).await.unwrap();
}
