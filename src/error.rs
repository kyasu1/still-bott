use crate::gq::error::HasuraError;
use snafu::prelude::*;

#[derive(Debug, Snafu)]
#[snafu(visibility(pub(crate)))]
pub enum Error {
    GraphqlError {
        source: HasuraError,
    },

    MinioError {
        source: crate::minio::Error,
    },

    TwitterError {
        source: crate::twitter::Error,
    },

    #[snafu(whatever, display("{message}"))]
    Whatever {
        message: String,
        #[snafu(source(from(Box<dyn std::error::Error + Send + Sync>, Some)))]
        source: Option<Box<dyn std::error::Error + Send + Sync>>,
    },
}
