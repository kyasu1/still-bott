use super::error::{build_errors, HasuraError, NetworkSnafu};
use snafu::prelude::*;
/*
mutation StoreSession($access_token: String!, $expires_in: Int!, $id: String!, $issued_at: timestamptz!, $refresh_token: String!) {
    insert_session_one(
      object: {access_token: $access_token, expires_in: $expires_in, id: $id, refresh_token: $refresh_token, issued_at: $issued_at}
      on_conflict: {constraint: session_pkey, update_columns: [access_token, refresh_token, expires_in, issued_at]}
    ) {
      id
      expires_in
      access_token
      refresh_token
      issued_at
    }
  }
*/
#[allow(non_camel_case_types)]
#[cynic::schema_for_derives(file = r#"schema.graphql"#, module = "schema")]
mod queries {
    use crate::gq::common::scalars::*;
    use crate::gq::common::schema;

    #[derive(cynic::QueryVariables, Debug)]
    pub struct StoreSessionVariables {
        pub access_token: String,
        pub expires_in: Option<i32>,
        pub id: String,
        pub issued_at: Timestamptz,
        pub refresh_token: Option<String>,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[cynic(graphql_type = "mutation_root", variables = "StoreSessionVariables")]
    pub struct StoreSession {
        #[arguments(object: { access_token: $access_token, expires_in: $expires_in, id: $id, issued_at: $issued_at, refresh_token: $refresh_token }, on_conflict: { constraint: "session_pkey", update_columns: ["access_token", "refresh_token", "expires_in", "issued_at"] })]
        #[cynic(rename = "insert_session_one")]
        pub insert_session_one: Option<session>,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[allow(non_camel_case_types)]
    pub struct session {
        pub id: String,
        #[cynic(rename = "expires_in")]
        pub expires_in: Option<i32>,
        #[cynic(rename = "access_token")]
        pub access_token: String,
        #[cynic(rename = "refresh_token")]
        pub refresh_token: Option<String>,
        #[cynic(rename = "issued_at")]
        pub issued_at: Timestamptz,
    }
}

pub async fn store_session(token: crate::model::Token) -> Result<crate::model::Token, HasuraError> {
    use cynic::MutationBuilder;
    let vars = queries::StoreSessionVariables {
        id: token.id,
        access_token: token.access_token,
        refresh_token: token.refresh_token,
        expires_in: token.expires_in.map(|d| d.as_secs() as i32),
        issued_at: token.issued_at.into(),
    };

    let operation = queries::StoreSession::build(vars);

    let resp = super::common::run_graphql(operation)
        .await
        .context(NetworkSnafu)?;

    let session = resp
        .data
        .ok_or_else(|| build_errors(resp.errors))?
        .insert_session_one
        .ok_or(HasuraError::SessionNotFound)?;

    Ok(crate::model::Token::from_session(
        session.id,
        session.access_token,
        session.refresh_token,
        session.expires_in,
        session.issued_at.into(),
    ))
}
