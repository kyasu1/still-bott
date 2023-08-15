use s3::{creds::error::CredentialsError, error::S3Error};
use snafu::prelude::*;

#[derive(Debug, Snafu)]

pub enum Error {
    FailedGenerateCredentails { source: CredentialsError },
    FailedGetBucket { source: S3Error },
    FailedCreateBucket { source: S3Error },
}

pub async fn get_or_create_bucket(bucket_name: &str) -> Result<s3::Bucket, Error> {
    let region = s3::region::Region::Custom {
        region: "ap-northeast-1".to_owned(),
        endpoint: crate::config::CONFIG.minio_endpoint.clone(),
    };

    let credentials = s3::creds::Credentials::default().context(FailedGenerateCredentailsSnafu)?;

    let bucket = s3::bucket::Bucket::new(bucket_name, region.clone(), credentials.clone())
        .context(FailedGetBucketSnafu)?
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
                return Err(Error::FailedCreateBucket { source: err });
            }
        };
    }

    Ok(bucket)
}
