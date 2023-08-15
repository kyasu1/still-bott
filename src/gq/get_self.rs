/*
query GetSelfProfile($id: String!) {
  user_by_pk(id: $id) {
    email
    id
    role
    active
    last_seen
    email_confirm_code_issued_at
  }
}
*/
#[cynic::schema_for_derives(file = r#"schema.graphql"#, module = "schema")]
mod queries {
    use crate::gq::common::enums::*;
    use crate::gq::common::scalars::*;
    use crate::gq::common::schema;

    #[derive(cynic::QueryVariables, Debug)]
    pub struct GetSelfProfileVariables {
        pub id: String,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[cynic(graphql_type = "query_root", variables = "GetSelfProfileVariables")]
    pub struct GetSelfProfile {
        #[arguments(id: $id)]
        #[cynic(rename = "user_by_pk")]
        pub user_by_pk: Option<user>,
    }

    #[derive(cynic::QueryFragment, Debug)]
    #[allow(non_camel_case_types)]
    pub struct user {
        pub email: String,
        pub id: String,
        pub role: RoleEnum,
        pub active: bool,
        #[cynic(rename = "last_seen")]
        pub last_seen: Timestamptz,
        #[cynic(rename = "email_confirmed")]
        pub email_confirmed: bool,
        #[cynic(rename = "email_confirmed_at")]
        pub email_confirmed_at: Option<Timestamptz>,
        #[cynic(rename = "email_confirm_code")]
        pub email_confirm_code: Option<String>,
        #[cynic(rename = "email_confirm_code_issued_at")]
        pub email_confirm_code_issued_at: Option<Timestamptz>,
    }
}

// #[derive(Debug, Snafu)]
// pub enum GraphqlError {
//     Network {
//         source: cynic::http::CynicReqwestError,
//     },
//     Hasura {
//         source: cynic::GraphQlError,
//     },
//     #[snafu(display("data not found"))]
//     DataNotFound,
// }

use super::error::{build_errors, HasuraError, NetworkSnafu};

use snafu::prelude::*;

pub async fn get_self(user_id: String) -> Result<Option<crate::model::HasuraUser>, HasuraError> {
    use cynic::QueryBuilder;

    let vars = queries::GetSelfProfileVariables {
        id: user_id.clone(),
    };

    let operation = queries::GetSelfProfile::build(vars);

    let resp = super::common::run_graphql(operation)
        .await
        .context(NetworkSnafu)?;

    resp.data
        .ok_or_else(|| build_errors(resp.errors))
        .map(|data| {
            data.user_by_pk.map(|user| {
                let role = match user.role {
                    super::common::enums::RoleEnum::Anonymous => crate::model::Role::Anonymous,
                    super::common::enums::RoleEnum::Basic => crate::model::Role::Basic,
                    super::common::enums::RoleEnum::Premium => crate::model::Role::Premium,
                };

                let last_seen = time::PrimitiveDateTime::parse(
                    &user.last_seen.0,
                    &time::format_description::well_known::Iso8601::DEFAULT,
                )
                .unwrap();

                crate::model::HasuraUser {
                    id: user.id,
                    email: user.email,
                    role,
                    active: user.active,
                    last_seen,
                    email_confirmed: user.email_confirmed,
                    email_confirmed_at: user
                        .email_confirmed_at
                        .map(|email_confirmed_at| email_confirmed_at.into()),
                    email_confirm_code: user.email_confirm_code,
                    email_confirm_code_issued_at: user
                        .email_confirm_code_issued_at
                        .map(|email_confirm_code_issued_at| email_confirm_code_issued_at.into()),
                }
            })
        })
}

// fn build_errors(errors: Option<Vec<cynic::GraphQlError>>) -> GraphqlError {
//     match errors {
//         Some(errors) => match errors.first() {
//             Some(error) => GraphqlError::Hasura {
//                 source: error.clone(),
//             },
//             None => GraphqlError::DataNotFound,
//         },
//         None => GraphqlError::DataNotFound,
//     }
// }
