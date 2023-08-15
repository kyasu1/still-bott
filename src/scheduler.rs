// use crate::error::Error;
use crate::model::{EnabledTask, RssTask};
use clokwerk::AsyncScheduler;
use snafu::prelude::*;
use std::collections::HashMap;
use std::time::Duration;
use tokio;

#[derive(Debug, Snafu)]
#[snafu(visibility(pub(crate)))]
pub enum Error {
    GraphqlError {
        source: crate::gq::error::HasuraError,
    },
    FailedToStartTasks,
}
pub async fn start_scheduler(
) -> Result<HashMap<String, Option<tokio::task::JoinHandle<AsyncScheduler>>>, Error> {
    let users = crate::gq::list_active_tasks::list_active_tasks()
        .await
        .context(GraphqlSnafu)?;

    let handles = futures::future::join_all(users.iter().map(start_task)).await;

    Ok(HashMap::from_iter(handles))
}

async fn start_task(
    user: &crate::model::ActiveUser,
) -> (String, Option<tokio::task::JoinHandle<AsyncScheduler>>) {
    (
        user.user_id.clone(),
        start_tasks(&user.tasks, &user.rss_tasks).await,
    )
}

pub async fn start_task_for_user(
    user_id: String,
) -> Result<Option<tokio::task::JoinHandle<AsyncScheduler>>, Error> {
    let users = crate::gq::list_active_tasks_by_user::list_active_tasks_by_user(user_id.clone())
        .await
        .context(GraphqlSnafu)?;

    // let user = users.first().whatever_context(format!(
    //     "Failed to start task for user {} because there is no tasks",
    //     user_id,
    // ))?;
    let user = users.first().ok_or(Error::FailedToStartTasks)?;

    Ok(start_tasks(&user.tasks, &user.rss_tasks).await)
}

async fn start_tasks(
    tasks: &Vec<EnabledTask>,
    rss_tasks: &Vec<RssTask>,
) -> Option<tokio::task::JoinHandle<AsyncScheduler>> {
    let mut scheduler = AsyncScheduler::new();

    if tasks.len() > 0 {
        tasks
            .clone()
            .into_iter()
            .filter(|task| task.messages.len() > 0)
            .for_each(|task| EnabledTask::to_schedule2(task, &mut scheduler));
    }

    if rss_tasks.len() > 0 {
        rss_tasks
            .clone()
            .into_iter()
            .for_each(|task| RssTask::to_schedule2(task, &mut scheduler));
    }

    let handle = tokio::spawn(async move {
        loop {
            scheduler.run_pending().await;
            tokio::time::sleep(Duration::from_millis(1000)).await;
        }
    });

    Some(handle)
}
