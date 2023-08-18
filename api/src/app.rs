use crate::config::CONFIG;
use crate::logger;
use crate::routes;
use crate::state::AppState;

use axum::Router;
use http::{header, HeaderValue, Method, StatusCode};
use tower_http::{
    cors::CorsLayer,
    services::{ServeDir, ServeFile},
};

pub async fn create_app(app_state: AppState) -> Router {
    logger::setup();

    // let serve_dir = ServeDir::new("client/dist").not_found_service(handle_404.into_service());
    let serve_dir = ServeDir::new("./dist").not_found_service(ServeFile::new("./dist/index.html"));

    Router::new()
        .merge(routes::auth::create_route())
        .merge(routes::api::create_route())
        .merge(routes::html::create_route())
        .merge(Router::new().nest_service("/assets", ServeDir::new("./dist/assets")))
        .fallback_service(serve_dir)
        .layer(
            CorsLayer::new()
                .allow_origin(CONFIG.backend_endpoint.parse::<HeaderValue>().unwrap())
                .allow_credentials(true)
                .allow_headers([header::AUTHORIZATION, header::ACCEPT, header::CONTENT_TYPE])
                .allow_methods([Method::GET]),
        )
        .with_state(app_state)
}

async fn handle_404() -> (StatusCode, &'static str) {
    (StatusCode::NOT_FOUND, "Not found")
}
