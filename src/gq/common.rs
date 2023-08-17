#[cynic::schema("hasura")]
pub mod schema {}

#[cynic::schema_for_derives(file = r#"schema.graphql"#, module = "super::schema")]
pub mod scalars {
    use time::format_description::well_known::Rfc3339;

    #[derive(cynic::Scalar, Debug, Clone)]
    #[cynic(graphql_type = "timestamptz")]
    pub struct Timestamptz(pub String);

    impl From<Timestamptz> for time::OffsetDateTime {
        fn from(value: Timestamptz) -> Self {
            time::OffsetDateTime::parse(&value.0, &Rfc3339).unwrap()
        }
    }
    impl From<time::OffsetDateTime> for Timestamptz {
        fn from(value: time::OffsetDateTime) -> Self {
            Timestamptz(value.format(&Rfc3339).unwrap())
        }
    }

    #[derive(cynic::Scalar, Debug, Clone)]
    #[cynic(graphql_type = "time")]
    pub struct Time(pub String);

    // pub type Time = time::Time;
    // cynic::impl_scalar!(Time, schema::time);

    #[derive(cynic::Scalar, Debug, Clone)]
    #[cynic(graphql_type = "uuid")]
    pub struct Uuid(pub uuid::Uuid);
}

#[cynic::schema_for_derives(file = r#"schema.graphql"#, module = "super::schema")]
pub mod enums {
    #[derive(cynic::Enum, Clone, Copy, Debug)]
    #[cynic(graphql_type = "role_enum")]
    pub enum RoleEnum {
        #[cynic(rename = "anonymous")]
        Anonymous,
        #[cynic(rename = "basic")]
        Basic,
        #[cynic(rename = "premium")]
        Premium,
    }
}

impl From<crate::model::Role> for enums::RoleEnum {
    fn from(value: crate::model::Role) -> Self {
        use self::enums::RoleEnum;
        use crate::model::Role;

        match value {
            Role::Anonymous => RoleEnum::Anonymous,
            Role::Basic => RoleEnum::Basic,
            Role::Premium => RoleEnum::Premium,
        }
    }
}

pub async fn run_graphql<T, V>(
    operation: cynic::Operation<T, V>,
) -> Result<cynic::GraphQlResponse<T>, cynic::http::CynicReqwestError>
where
    T: serde::de::DeserializeOwned + 'static,
    V: serde::Serialize,
{
    use cynic::http::ReqwestExt;

    let client = reqwest::Client::new();
    client
        // .post(format!(
        //     "{}/v1/graphql",
        //     crate::config::CONFIG.hasura_graphql_endpoint.clone()
        // ))
        .post("http://graphql-engine:8080/v1/graphql")
        .header(
            "X-Hasura-Admin-Secret",
            &crate::config::CONFIG.hasura_graphql_admin_secret,
        )
        .run_graphql(operation)
        .await
}
