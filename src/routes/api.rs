use crate::{config::CONFIG, gq::error::HasuraError, model::*};
use axum::{
    extract::{Multipart, State},
    middleware,
    response::IntoResponse,
    routing::post,
    Json, Router,
};

use crate::twitter::TwitterUser;
use http::StatusCode;
use mail_send::{mail_builder::MessageBuilder, SmtpClientBuilder};
use serde::{Deserialize, Serialize};
use snafu::prelude::*;
use time::OffsetDateTime;

pub fn create_route() -> Router<crate::state::AppState> {
    Router::new()
        // .route("/api/v1/tweets", post(tweet))
        // .route("/api/v1/upload", post(upload))
        .route("/api/v1/delete_image", post(delete_image))
        .route("/api/v1/restart_scheduler", post(restart_scheduler))
        .route("/api/v1/register_email", post(register_email))
        .route("/api/v1/confirm_email", post(confirm_email))
        .route("/api/v1/minio_get_upload_url", post(minio_get_upload_url))
        .route("/api/v1/save_media", post(save_media))
        .layer(middleware::from_fn(action_auth_middleware))
}

#[derive(Deserialize, Serialize, Debug)]
struct FormInput {
    text: String,
}

// async fn tweet(
//     State(oauth_client): State<BasicClient>,
//     Json(input): Json<FormInput>,
//     user: TwitterUser,
// ) -> Result<Json<TweetsResponse>, ApiError> {
//     if let Ok(token) =
//         crate::gq::load_session::load_session(user.id.clone(), oauth_client.clone()).await
//     {
//         let client = reqwest::Client::new();

//         let resp = client
//             .post("https://api.twitter.com/2/tweets")
//             .json(&input)
//             .bearer_auth(token.access_token)
//             .send()
//             .await;

//         let data = resp.json::<Data<TweetsResponse>>().await?;

//         match resp {
//             Ok(resp) => match resp.json::<Data<TweetsResponse>>().await {
//                 Ok(data) => Ok(Json(data.data)),
//                 Err(_) => Err(StatusCode::UNPROCESSABLE_ENTITY),
//             },
//             Err(err) => match err.status() {
//                 Some(s) => Err(s),
//                 None => Err(StatusCode::UNPROCESSABLE_ENTITY),
//             },
//         }
//     } else {
//         Err(ApiError::Unauthenticted)
//     }
// }

#[derive(Deserialize, Debug)]
struct RegisterEmailInput {
    email: String,
}
#[derive(Serialize, Debug)]
struct RegisterEmailOutput {
    email: String,
}

#[derive(Deserialize, Debug)]
struct ActionPayload<I> {
    input: Args<I>,
    session_variables: SessionVariables,
}

#[derive(Deserialize, Debug)]
struct Args<I> {
    args: I,
}

#[derive(Deserialize, Debug)]
#[allow(dead_code)]
struct SessionVariables {
    #[serde(rename = "x-hasura-user-id")]
    x_hasura_user_id: String,
    #[serde(rename = "x-hasura-role")]
    x_hasura_role: String,
}

#[derive(Serialize, Debug)]
struct ErrorResponse {
    message: String,
    extensions: Extensions,
}

#[derive(Serialize, Debug)]
struct Extensions {
    code: String,
}

impl IntoResponse for ApiError {
    fn into_response(self) -> axum::response::Response {
        let (message, code) = match self {
            ApiError::UserNotFound => (
                String::from("ユーザーの登録が確認できません"),
                self.to_string(),
            ),
            ApiError::PermissionDenied => (
                String::from("メールアドレスは既に認証ずみです"),
                String::from("PermissionDenied"),
            ),
            ApiError::InvalidEmail => (
                String::from("不正なメールアドレスです"),
                String::from("InvalidEmail"),
            ),
            ApiError::CodeNotMatch => (String::from("認証コードが一致しません"), self.to_string()),
            ApiError::CodeNotRegistered => (
                String::from("認証コードが登録されていません"),
                self.to_string(),
            ),
            ApiError::CodeExpired => (
                String::from("認証コードの有効期限が過ぎています"),
                self.to_string(),
            ),
            ApiError::InavlidCode => (String::from("数字6桁で入力してください"), self.to_string()),
            ApiError::SendEmail { source } => (
                format!("メール送信時にエラーが発生しました{}", source),
                source.to_string(),
            ),
            ApiError::UpdateEmailProhibited => (
                String::from("メールアドレスの再設定が許可されていません"),
                self.to_string(),
            ),

            ApiError::Generic { message, source } => (message, format!("{:?}", source)),
            _ => (self.to_string(), self.to_string()),
        };

        tracing::error!(message);
        let extensions = Extensions { code };
        let body = Json(ErrorResponse {
            message,
            extensions,
        });

        (StatusCode::BAD_REQUEST, body).into_response()
    }
}

#[derive(Debug, Snafu)]
enum ApiError {
    UserNotFound,

    PermissionDenied,

    InvalidEmail,

    InavlidCode,

    CodeNotMatch,

    CodeNotRegistered,

    CodeExpired,

    Hasura {
        source: crate::gq::error::HasuraError,
    },

    FailedGetPresignedPost {
        source: s3::error::S3Error,
    },

    FailedToSaveMedia {
        source: HasuraError,
    },

    SMTPServerUnrechable {
        source: mail_send::Error,
    },

    SendEmail {
        source: mail_send::Error,
    },

    UpdateEmailProhibited,

    #[snafu(whatever, display("{message}"))]
    Generic {
        message: String,
        #[snafu(source(from(Box<dyn std::error::Error>, Some)))]
        source: Option<Box<dyn std::error::Error>>,
    },
}

#[axum_macros::debug_handler]
async fn register_email(
    action: Json<ActionPayload<RegisterEmailInput>>,
) -> Result<Json<RegisterEmailOutput>, ApiError> {
    let email = action.input.args.email.clone();
    ensure!(!email.is_empty(), InvalidEmailSnafu);

    let hasura_user =
        crate::gq::get_self::get_self(action.session_variables.x_hasura_user_id.clone())
            .await
            .context(HasuraSnafu)?;

    let now = time::OffsetDateTime::now_utc();
    if can_upsert_email(hasura_user, now) {
        let code: String = random_number::random_ranged(100000..=999999).to_string();

        crate::gq::upsert_email::exec(
            email.clone(),
            Some(code.clone()),
            Some(now.clone()),
            false,
            None,
            action.session_variables.x_hasura_user_id.clone(),
            crate::model::Role::Anonymous,
        )
        .await
        .context(HasuraSnafu)?;

        send_code_by_email(code, email.clone()).await?;

        Ok(Json(RegisterEmailOutput { email }))
    } else {
        Err(ApiError::UpdateEmailProhibited)
    }
}

fn can_upsert_email(user: Option<crate::model::HasuraUser>, now: OffsetDateTime) -> bool {
    match user {
        Some(user) => match user.email_confirm_code_issued_at {
            Some(email_confirm_code_issued_at) => {
                passed_specified_minutes(email_confirm_code_issued_at, now, 5)
            }
            None => true,
        },

        None => true,
    }
}

fn passed_specified_minutes(issued_at: OffsetDateTime, now: OffsetDateTime, minutes: u32) -> bool {
    now - issued_at > time::Duration::minutes(minutes as i64)
}

async fn send_code_by_email(code: String, email: String) -> Result<(), ApiError> {
    tracing::info!("Sending confirmation code {}", code);

    let message = MessageBuilder::new()
        .from("Still Bott Registration")
        .to(vec![email])
        .subject("Still Bottへの登録コードをお知らせします")
        .text_body(format!(
            "10分以内に下記の登録コード\n\n{}\n\nを入力してください",
            code,
        ));

    let mut client = SmtpClientBuilder::new("smtp.gmail.com", 587)
        .implicit_tls(false)
        .credentials((CONFIG.smtp_username.as_ref(), CONFIG.smtp_password.as_ref()))
        .connect()
        .await
        .context(SMTPServerUnrechableSnafu)?;

    client.send(message).await.context(SendEmailSnafu)
}

#[derive(Deserialize, Debug)]
struct ConfirmEmailInput {
    email: String,
    code: String,
}

#[derive(Serialize, Debug)]
struct ConfrimEmailOutput {
    result: bool,
}

async fn confirm_email(
    action: Json<ActionPayload<ConfirmEmailInput>>,
) -> Result<Json<ConfrimEmailOutput>, ApiError> {
    // 1. Get code from User table
    // 2. Confirm the time issued is within the valid time range (10mins ?)
    // 3. Check the code matches
    // 4. Everything ok, update the status of User table
    // The confimration must be done on the database level not the server
    ensure!(
        action.input.args.code.len() == 6
            && (action.input.args.code.chars().all(|x| x.is_numeric())),
        InavlidCodeSnafu
    );

    let hasura_user =
        crate::gq::get_self::get_self(action.session_variables.x_hasura_user_id.clone())
            .await
            .context(HasuraSnafu)?
            .ok_or(ApiError::UserNotFound)?;

    if hasura_user.email_confirmed {
        Err(ApiError::PermissionDenied)
    } else {
        match (
            hasura_user.email_confirm_code,
            hasura_user.email_confirm_code_issued_at,
        ) {
            (Some(email_confirm_code), Some(email_confirm_code_issued_at)) => {
                if can_confirm_email(
                    email_confirm_code_issued_at,
                    time::OffsetDateTime::now_utc(),
                ) {
                    if email_confirm_code == action.input.args.code
                        && hasura_user.email == action.input.args.email
                    {
                        crate::gq::upsert_email::exec(
                            action.input.args.email.clone(),
                            None,
                            None,
                            true,
                            Some(OffsetDateTime::now_utc()),
                            action.session_variables.x_hasura_user_id.clone(),
                            crate::model::Role::Basic,
                        )
                        .await
                        .context(HasuraSnafu)?;

                        Ok(Json(ConfrimEmailOutput { result: true }))
                    } else {
                        Err(ApiError::CodeNotMatch)
                    }
                } else {
                    Err(ApiError::CodeExpired)
                }
            }
            _ => Err(ApiError::CodeNotRegistered),
        }
    }
}

fn can_confirm_email(issued_at: OffsetDateTime, now: OffsetDateTime) -> bool {
    now - issued_at <= time::Duration::minutes(10)
}

#[derive(Deserialize, Debug)]
struct MinioGetUploadUrlInput {}

#[derive(Serialize, Debug)]
struct MinioGetUploadUrlOutput {
    url: String,
    #[serde(rename = "mediaId")]
    media_id: uuid::Uuid,
}
async fn minio_get_upload_url(
    action: Json<ActionPayload<MinioGetUploadUrlInput>>,
) -> Result<Json<MinioGetUploadUrlOutput>, ApiError> {
    let bucket_name = action.session_variables.x_hasura_user_id.clone();
    let bucket = get_or_create_bucket(&bucket_name).await?;
    let media_id = uuid::Uuid::new_v4();
    let url = bucket
        .presign_put(media_id.to_string(), 86400, None)
        .context(FailedGetPresignedPostSnafu)?;

    Ok(Json(MinioGetUploadUrlOutput { url, media_id }))
}

async fn get_or_create_bucket(bucket_name: &str) -> Result<s3::Bucket, ApiError> {
    let region = s3::region::Region::Custom {
        region: "ap-northeast-1".to_owned(),
        endpoint: crate::config::CONFIG.minio_endpoint.clone(),
    };

    let credentials =
        s3::creds::Credentials::default().whatever_context("Failed to generate S3 Credentials")?;

    let bucket = s3::bucket::Bucket::new(bucket_name, region.clone(), credentials.clone())
        .whatever_context("Failed generate S3 Bucket")?
        .with_path_style();

    // もし既存のバケットが存在しない場合には新たに作成する
    if bucket.head_object("/").await.is_err() {
        let config = s3::BucketConfiguration::default();
        match s3::bucket::Bucket::create_with_path_style(bucket_name, region, credentials, config)
            .await
        {
            Ok(_) => {
                tracing::info!("Bucket {} created", bucket_name);
            }
            Err(err) => {
                tracing::error!("Failed to create bucket {}", bucket_name);
                tracing::error!("{:?}", err);
                whatever!("Failed to create bucke {}", bucket_name);
            }
        };
    }

    Ok(bucket)
}

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct DeleteImageInput {
    media_id: uuid::Uuid,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct DeleteImageOutput {
    media_id: uuid::Uuid,
}

async fn delete_image(
    payload: Json<ActionPayload<DeleteImageInput>>,
) -> Result<Json<DeleteImageOutput>, ApiError> {
    let bucket_name = payload.session_variables.x_hasura_user_id.clone();
    let bucket = get_or_create_bucket(&bucket_name).await?;

    // Ignore if
    let status = bucket
        .delete_object(payload.input.args.media_id.to_string())
        .await
        .map(|response| response.status_code());
    if status.is_err() {
        tracing::warn!(
            "media {} was not found on minio, skipping",
            payload.input.args.media_id.clone()
        );
    }

    crate::gq::delete_media::exec(payload.input.args.media_id.clone())
        .await
        .map(|_| {
            Json(DeleteImageOutput {
                media_id: payload.input.args.media_id.clone(),
            })
        })
        .context(HasuraSnafu)
}

#[derive(Debug, Deserialize)]
struct SaveMediaInput {
    #[serde(rename = "mediaId")]
    media_id: uuid::Uuid,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct SaveMediaOutput {
    id: uuid::Uuid,
    user_id: String,
    thumbnail: String,
    #[serde(with = "time::serde::rfc3339")]
    uploaded_at: OffsetDateTime,
}

// ここではmedia_idをパラメータとして受け取り、minioに保存された画像データを取得し、
// サムネイルを作成した上で、Hasuraのmediaテーブルにuser_idと紐づけて保存する。
// 保存されたmediaを戻す
async fn save_media(
    payload: Json<ActionPayload<SaveMediaInput>>,
) -> Result<Json<SaveMediaOutput>, ApiError> {
    let bucket_name = payload.session_variables.x_hasura_user_id.clone();
    let bucket = get_or_create_bucket(&bucket_name).await?;

    let object = bucket
        .get_object(payload.input.args.media_id.to_string())
        .await
        .whatever_context(format!(
            "Failed to get the image `{}` from minio",
            payload.input.args.media_id
        ))?;

    let image_original = image::io::Reader::new(std::io::Cursor::new(object.bytes()))
        .with_guessed_format()
        .whatever_context("Failed to read bytes as an image")?
        .decode()
        .whatever_context("Failed to decode as image")?;

    let image_thumb = image_original.thumbnail(240, 240).to_rgb8();

    let mut bytes: Vec<u8> = Vec::new();
    image_thumb
        .write_to(
            &mut std::io::Cursor::new(&mut bytes),
            image::ImageOutputFormat::Jpeg(85),
        )
        .whatever_context("Failed to generate thumbnail")?;

    use base64::Engine as _;
    let base64 = base64::engine::general_purpose::STANDARD.encode(bytes);
    let thumbnail = format!("data:image/jpeg;base64,{}", base64);

    let media = crate::gq::upload_media::upload_media(
        bucket_name.clone(),
        payload.input.args.media_id.clone(),
        thumbnail.clone(),
    )
    .await
    .context(FailedToSaveMediaSnafu)?;

    Ok(Json(SaveMediaOutput {
        id: media.id,
        user_id: media.user_id,
        thumbnail,
        uploaded_at: media.uploaded_at,
    }))
}

// OBSOLETE
#[allow(dead_code)]
async fn upload(
    user: TwitterUser,
    mut multipart: Multipart,
) -> Result<Json<crate::model::Media>, StatusCode> {
    if let Some(file) = multipart
        .next_field()
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    {
        let data = file
            .bytes()
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        let uuid = uuid::Uuid::new_v4();

        let image_original = image::io::Reader::new(std::io::Cursor::new(data.clone()))
            .with_guessed_format()
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
            .decode()
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        let image_resized = if image_original.width() > 1200 {
            image_original
                .resize(1200, 1200, image::imageops::FilterType::Gaussian)
                .to_rgb8()
        } else {
            image_original.to_rgb8()
        };

        let image_thumb = image_original.thumbnail(240, 240).to_rgb8();

        let bucket_name = user.id.clone();
        let region = s3::region::Region::Custom {
            region: "ap-northeast-1".to_owned(),
            endpoint: crate::config::CONFIG.minio_endpoint.clone(),
        };

        let credentials = s3::creds::Credentials::default().unwrap();
        let bucket = s3::bucket::Bucket::new(&bucket_name, region.clone(), credentials.clone())
            .unwrap()
            .with_path_style();

        // もし既存のバケットが存在しない場合には新たに作成する
        if bucket.head_object("/").await.is_err() {
            let config = s3::BucketConfiguration::default();
            match s3::bucket::Bucket::create_with_path_style(
                &bucket_name,
                region,
                credentials,
                config,
            )
            .await
            {
                Ok(_) => {
                    tracing::info!("New bucket is created for user {}", user.id);
                }
                Err(err) => {
                    tracing::debug!("{:?}", err);
                    return Err(StatusCode::INTERNAL_SERVER_ERROR);
                }
            };
        }

        let mut bytes: Vec<u8> = Vec::new();
        image_resized
            .write_to(
                &mut std::io::Cursor::new(&mut bytes),
                image::ImageOutputFormat::Jpeg(85),
            )
            .map_err(|err| {
                tracing::debug!("Image conversion error {}", err);
                StatusCode::INTERNAL_SERVER_ERROR
            })?;

        // このフラグでminioへのアップロード済みかどうかを判断し、データベースに保存する？
        let _uploaded = match bucket.put_object(uuid.to_string(), &bytes).await {
            Ok(resp) => {
                if resp.status_code() != 200 {
                    tracing::debug!(
                        "minioへファイルアップロード時に200以外のステータスが返されました: {:?}",
                        resp
                    );
                    false
                } else {
                    true
                }
            }
            Err(err) => {
                tracing::debug!("minioへファイルアップロード時にエラー: {:?}", err);
                false
            }
        };

        let mut bytes: Vec<u8> = Vec::new();
        image_thumb
            .write_to(
                &mut std::io::Cursor::new(&mut bytes),
                image::ImageOutputFormat::Jpeg(85),
            )
            .map_err(|err| {
                tracing::debug!("Image conversion error {}", err);
                StatusCode::INTERNAL_SERVER_ERROR
            })?;

        use base64::Engine as _;
        let base64 = base64::engine::general_purpose::STANDARD.encode(bytes);
        let dataurl = format!("data:image/jpeg;base64,{}", base64);

        match crate::gq::upload_media::upload_media(user.id, uuid.clone(), dataurl).await {
            Ok(media) => Ok(Json(media)),
            _ => Err(StatusCode::BAD_REQUEST),
        }
    } else {
        Err(StatusCode::BAD_REQUEST)
    }
}

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct BooleanInput {
    dummy: bool,
}

#[derive(Debug, Serialize)]
struct BooleanOutput {
    result: bool,
}

async fn restart_scheduler(
    State(actor_handle): State<crate::mpsc::ActorHandle>,
    payload: Json<ActionPayload<BooleanInput>>,
) -> Result<Json<BooleanOutput>, ApiError> {
    let result = actor_handle
        .restart_task_for_user(payload.session_variables.x_hasura_user_id.clone())
        .await;
    Ok(Json(BooleanOutput { result }))
}

async fn action_auth_middleware<B>(
    request: http::Request<B>,
    next: axum::middleware::Next<B>,
) -> Result<axum::response::Response, StatusCode>
where
    B: Send,
{
    let (parts, body) = request.into_parts();
    let hasura_action_secret = CONFIG.hasura_action_secret.clone();

    if let Some(action_secret) = parts.headers.get("ACTION_SECRET") {
        if action_secret == &hasura_action_secret {
            let request = axum::http::Request::from_parts(parts, body);

            Ok(next.run(request).await)
        } else {
            Err(StatusCode::UNAUTHORIZED)
        }
    } else {
        Err(StatusCode::UNAUTHORIZED)
    }
}

#[tokio::test]
async fn create_bucket_test() {
    let bucket = get_or_create_bucket("test").await.unwrap();

    assert_eq!(bucket.name, "test");
}
