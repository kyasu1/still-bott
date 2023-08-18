use crate::model::*;
use crate::twitter::TwitterUser;
use askama::Template;
use axum::{
    response::{Html, IntoResponse, Redirect, Response},
    routing::get,
    Router,
};
use http::StatusCode;

pub fn create_route() -> Router<crate::state::AppState> {
    Router::new().route("/login", get(login))
}

#[derive(Template)]
#[template(path = "login.html")]
struct LoginTemplate {}

pub async fn login(user: Option<TwitterUser>) -> impl IntoResponse {
    if user.is_some() {
        Redirect::to("/").into_response()
    } else {
        let template = LoginTemplate {};
        HtmlTemplate(template).into_response()
    }
}

struct HtmlTemplate<T>(T);

impl<T> IntoResponse for HtmlTemplate<T>
where
    T: Template,
{
    fn into_response(self) -> Response {
        match self.0.render() {
            Ok(html) => Html(html).into_response(),
            Err(err) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("Failed to render template. Error: {}", err),
            )
                .into_response(),
        }
    }
}
