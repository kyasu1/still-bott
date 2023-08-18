/*
mutation UpsertEmail (
  $email: String!
  $id: String!
  $email_confirm_code: String
  $email_confirm_code_issued_at: timestamptz
  $email_confirmed: Boolean!
  $email_confirmed_at: timestamptz
  $role: role_enum!
) {
  insert_user_one(
    object: {
      email: $email
      id: $id
      email_confirm_code: $email_confirm_code
      email_confirm_code_issued_at: $email_confirm_code_issued_at
      email_confirmed_at: $email_confirmed_at
      email_confirmed: $email_confirmed
      role: $role
    }
    on_conflict: {
      constraint: user_pkey
      update_columns: [
        email
        email_confirm_code
        email_confirm_code_issued_at
        email_confirmed
        email_confirmed_at
        role
      ]
    }
  ) {
    id
  }
}
*/

#[allow(non_camel_case_types)]
#[cynic::schema_for_derives(file = r#"schema.graphql"#, module = "schema")]
mod queries {
    use crate::gq::common::enums::RoleEnum;
    use crate::gq::common::scalars::*;
    use crate::gq::common::schema;

    #[derive(cynic::QueryVariables, Debug)]
    pub struct UpsertEmailVariables<'a> {
        pub email: &'a str,
        pub email_confirm_code: Option<&'a str>,
        pub email_confirm_code_issued_at: Option<Timestamptz>,
        pub email_confirmed: bool,
        pub email_confirmed_at: Option<Timestamptz>,
        pub id: &'a str,
        pub role: RoleEnum,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[cynic(graphql_type = "mutation_root", variables = "UpsertEmailVariables")]
    pub struct UpsertEmail {
        #[arguments(object: {email: $email, email_confirm_code: $email_confirm_code, email_confirm_code_issued_at: $email_confirm_code_issued_at, email_confirmed: $email_confirmed, email_confirmed_at: $email_confirmed_at, id: $id, role: $role}, on_conflict: { constraint: "user_pkey", update_columns: ["email", "email_confirm_code", "email_confirm_code_issued_at", "email_confirmed", "email_confirmed_at", "role"] })]
        #[cynic(rename = "insert_user_one")]
        pub insert_user_one: Option<User>,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[cynic(graphql_type = "user")]
    pub struct User {
        pub id: String,
    }
}

use super::error::{build_errors, HasuraError, NetworkSnafu};
use snafu::prelude::*;
use time::OffsetDateTime;

pub async fn exec(
    email: String,
    email_confirm_code: Option<String>,
    email_confirm_code_issued_at: Option<OffsetDateTime>,
    email_confirmed: bool,
    email_confirmed_at: Option<OffsetDateTime>,
    id: String,
    role: crate::model::Role,
) -> Result<(), HasuraError> {
    use cynic::MutationBuilder;

    let args = queries::UpsertEmailVariables {
        email: &email,
        email_confirm_code: email_confirm_code.as_deref(),
        email_confirm_code_issued_at: email_confirm_code_issued_at.map(Into::into),
        email_confirmed,
        email_confirmed_at: email_confirmed_at.map(Into::into),
        id: &id,
        role: role.into(),
    };

    let operation = queries::UpsertEmail::build(args);

    let resp = super::common::run_graphql(operation)
        .await
        .context(NetworkSnafu)?;

    resp.data
        .ok_or_else(|| build_errors(resp.errors))
        .and_then(|data| match data.insert_user_one {
            Some(_) => Ok(()),
            None => Err(HasuraError::DataNotFound),
        })
}
