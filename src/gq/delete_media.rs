/*
mutation DeleteMedia($id: uuid!) {
  delete_media_by_pk(id: $id) {
    id
  }
}
*/
#[cynic::schema_for_derives(file = r#"schema.graphql"#, module = "schema")]
mod queries {
    use crate::gq::common::scalars::*;
    use crate::gq::common::schema;

    #[derive(cynic::QueryVariables, Debug)]
    pub struct DeleteMediaVariables {
        pub id: Uuid,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[cynic(graphql_type = "mutation_root", variables = "DeleteMediaVariables")]
    pub struct DeleteMedia {
        #[arguments(id: $id)]
        #[cynic(rename = "delete_media_by_pk")]
        pub delete_media_by_pk: Option<Media>,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[cynic(graphql_type = "media")]
    pub struct Media {
        pub id: Uuid,
    }
}

use super::error::{build_errors, HasuraError, NetworkSnafu};
use snafu::prelude::*;
pub async fn exec(media_id: uuid::Uuid) -> Result<uuid::Uuid, HasuraError> {
    use cynic::MutationBuilder;

    let input = self::queries::DeleteMediaVariables {
        id: crate::gq::common::scalars::Uuid(media_id),
    };

    let operation = self::queries::DeleteMedia::build(input);

    let resp = super::common::run_graphql(operation)
        .await
        .context(NetworkSnafu)?;

    resp.data
        .ok_or_else(|| build_errors(resp.errors))
        .and_then(|data| match data.delete_media_by_pk {
            Some(media) => Ok(media.id.0),
            None => Err(HasuraError::DataNotFound),
        })
}
