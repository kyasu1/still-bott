/*
mutation UploadMedia($id: uuid!, $thumbnail: String!, $user_id: String!) {
    insert_media_one(object: {id: $id, thumbnail: $thumbnail, user_id: $user_id}) {
      id
      thumbnail
      uploaded_at
      user_id
    }
  }
*/
#[cynic::schema_for_derives(file = r#"schema.graphql"#, module = "schema")]
mod queries {
    use crate::gq::common::scalars::*;
    use crate::gq::common::schema;

    #[derive(cynic::QueryVariables, Debug)]
    pub struct UploadMediaVariables {
        pub id: Uuid,
        pub thumbnail: String,
        pub user_id: String,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[cynic(graphql_type = "mutation_root", variables = "UploadMediaVariables")]
    pub struct UploadMedia {
        #[arguments(object: { id: $id, thumbnail: $thumbnail, user_id: $user_id })]
        #[cynic(rename = "insert_media_one")]
        pub insert_media_one: Option<media>,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[allow(non_camel_case_types)]
    pub struct media {
        pub id: Uuid,
        pub thumbnail: String,
        #[cynic(rename = "uploaded_at")]
        pub uploaded_at: Timestamptz,
        #[cynic(rename = "user_id")]
        pub user_id: String,
    }
}

use super::error::{build_errors, HasuraError, NetworkSnafu};
use snafu::prelude::*;

pub async fn upload_media(
    user_id: String,
    uuid: uuid::Uuid,
    dataurl: String,
) -> Result<crate::model::Media, HasuraError> {
    use cynic::MutationBuilder;

    let input = self::queries::UploadMediaVariables {
        id: crate::gq::common::scalars::Uuid(uuid),
        thumbnail: dataurl,
        user_id,
    };

    let operation = self::queries::UploadMedia::build(input);

    let resp = super::common::run_graphql(operation)
        .await
        .context(NetworkSnafu)?;

    resp.data
        .ok_or_else(|| build_errors(resp.errors))
        .and_then(|data| match data.insert_media_one {
            Some(media) => {
                let format: time::format_description::well_known::iso8601::Iso8601 =
                    time::format_description::well_known::Iso8601;
                let updated_at: time::OffsetDateTime =
                    time::OffsetDateTime::parse(&media.uploaded_at.0, &format).unwrap();

                Ok(crate::model::Media::new(
                    media.id.0,
                    media.user_id,
                    media.thumbnail,
                    updated_at,
                ))
            }
            None => Err(HasuraError::DataNotFound),
        })
}
