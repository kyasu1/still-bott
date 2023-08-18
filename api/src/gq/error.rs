use snafu::Snafu;

#[derive(Debug, Snafu)]
#[snafu(visibility(pub(crate)))]
pub enum HasuraError {
    Network {
        source: cynic::http::CynicReqwestError,
    },
    Hasura {
        source: cynic::GraphQlError,
    },
    #[snafu(display("data not found"))]
    DataNotFound,

    SessionNotFound,

    #[snafu(whatever, display("{message}"))]
    Whatever {
        message: String,
        #[snafu(source(from(Box<dyn std::error::Error  + Send + Sync>, Some)))]
        source: Option<Box<dyn std::error::Error + Send + Sync>>,
    },
}

pub fn build_errors(errors: Option<Vec<cynic::GraphQlError>>) -> HasuraError {
    match errors {
        Some(errors) => match errors.first() {
            Some(error) => HasuraError::Hasura {
                source: error.clone(),
            },
            None => HasuraError::DataNotFound,
        },
        None => HasuraError::DataNotFound,
    }
}
