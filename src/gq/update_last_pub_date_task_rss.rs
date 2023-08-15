/*
mutation update_last_pub_date_task_rss($id: uuid!, $last_pub_date: timestamptz!, $updated_at: timestamptz!) {
  update_task_rss_by_pk(
    pk_columns: {id: $id}
    _set: {last_pub_date: $last_pub_date, updated_at: $updated_at}
  ) {
    id
  }
}
*/

use super::error::{build_errors, HasuraError, NetworkSnafu};
use snafu::prelude::*;
use time::OffsetDateTime;

#[cynic::schema_for_derives(file = r#"schema.graphql"#, module = "schema")]
mod queries {
    use crate::gq::common::scalars::*;
    use crate::gq::common::schema;

    #[derive(cynic::QueryVariables, Debug)]
    pub struct UpdateLastPubDateTaskRssVariables {
        pub id: Uuid,
        pub last_pub_date: Timestamptz,
        pub updated_at: Timestamptz,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[cynic(
        graphql_type = "mutation_root",
        variables = "UpdateLastPubDateTaskRssVariables"
    )]
    pub struct UpdateLastPubDateTaskRss {
        #[arguments(pk_columns: { id: $id }, _set: { last_pub_date: $last_pub_date, updated_at: $updated_at })]
        #[cynic(rename = "update_task_rss_by_pk")]
        pub update_task_rss_by_pk: Option<TaskRss>,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[cynic(graphql_type = "task_rss")]
    pub struct TaskRss {
        pub id: Uuid,
    }
}

pub async fn exec(
    id: uuid::Uuid,
    last_pub_date: OffsetDateTime,
) -> Result<uuid::Uuid, HasuraError> {
    use cynic::MutationBuilder;
    let vars = queries::UpdateLastPubDateTaskRssVariables {
        id: crate::gq::common::scalars::Uuid(id),
        last_pub_date: last_pub_date.into(),
        updated_at: time::OffsetDateTime::now_utc().into(),
    };

    let operation: cynic::Operation<
        queries::UpdateLastPubDateTaskRss,
        queries::UpdateLastPubDateTaskRssVariables,
    > = queries::UpdateLastPubDateTaskRss::build(vars);

    let resp = super::common::run_graphql(operation)
        .await
        .context(NetworkSnafu)?;

    let id = resp
        .data
        .ok_or_else(|| build_errors(resp.errors))?
        .update_task_rss_by_pk
        .ok_or(HasuraError::DataNotFound)?
        .id
        .0;

    Ok(id)
}
