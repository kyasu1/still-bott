/*
query LoadSession($id: String!) {
  session_by_pk(id: $id) {
    access_token
    expires_in
    issued_at
    refresh_token
    id
  }
}
*/
#[cynic::schema_for_derives(file = r#"schema.graphql"#, module = "schema")]
mod queries {
    use crate::gq::common::scalars::*;
    use crate::gq::common::schema;

    #[derive(cynic::QueryVariables, Debug)]
    pub struct LoadSessionVariables {
        pub id: String,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[cynic(graphql_type = "query_root", variables = "LoadSessionVariables")]
    pub struct LoadSession {
        #[arguments(id: $id)]
        #[cynic(rename = "session_by_pk")]
        pub session_by_pk: Option<session>,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[allow(non_camel_case_types)]
    pub struct session {
        #[cynic(rename = "access_token")]
        pub access_token: String,
        #[cynic(rename = "expires_in")]
        pub expires_in: Option<i32>,
        #[cynic(rename = "issued_at")]
        pub issued_at: Timestamptz,
        #[cynic(rename = "refresh_token")]
        pub refresh_token: Option<String>,
        pub id: String,
    }
}

use super::error::{build_errors, HasuraError, NetworkSnafu};
use oauth2::basic::BasicClient;
use snafu::prelude::*;

pub async fn load_session(
    user_id: String,
    oauth_client: BasicClient,
) -> Result<crate::model::Token, HasuraError> {
    use cynic::QueryBuilder;

    let vars = queries::LoadSessionVariables {
        id: user_id.clone(),
    };

    let operation: cynic::Operation<queries::LoadSession, queries::LoadSessionVariables> =
        queries::LoadSession::build(vars);

    // let token = super::common::run_graphql(operation)
    //     .await
    //     .map_err(|err| err.to_string())
    //     .and_then(|resp| resp.data.ok_or("NOT FOUND".to_string()))
    //     .and_then(|data| data.session_by_pk.ok_or("NOT FOUND".to_string()))
    //     .and_then(|session| {
    //         crate::model::Token::from_session(
    //             session.id,
    //             session.access_token,
    //             session.refresh_token,
    //             session.expires_in,
    //             session.issued_at.0,
    //         )
    //     })?;

    let resp = super::common::run_graphql(operation)
        .await
        .context(NetworkSnafu)?;
    let session = resp
        .data
        .ok_or_else(|| build_errors(resp.errors))?
        .session_by_pk
        .ok_or(HasuraError::SessionNotFound)?;

    let token = crate::model::Token::from_session(
        session.id,
        session.access_token,
        session.refresh_token,
        session.expires_in,
        session.issued_at.into(),
    );

    if token_expired(token.issued_at, token.expires_in) {
        let refresh_token = token
            .refresh_token
            .whatever_context("RefreshToken not found")?;

        let new_token = crate::twitter::refresh_token(oauth_client, user_id.clone(), refresh_token)
            .await
            .with_whatever_context(|err| err.to_string())?;

        super::store_session::store_session(new_token.clone()).await
    } else {
        Ok(token)
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
