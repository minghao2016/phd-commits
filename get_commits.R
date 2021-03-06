get_commits <- function(path, distinct = TRUE, filter = TRUE,
                        users = c("l.zappia", "lazappi", "Luke Zappia"),
                        from = "2016-02-08") {

    dirs <- fs::dir_ls(path, type = "directory")

    message("Searching ", length(dirs), " directories...")

    commits <- purrr::map_dfr(dirs, function(dir) {
        message("Processing ", fs::path_file(dir), "...")
        if (git2r::in_repository(dir)) {
            commits_list <- git2r::commits(dir)
            if (length(commits_list) > 0) {
                dir_commits <- purrr::map_dfr(commits_list, function(commit) {
                    tibble::tibble(
                        SHA  = commit$sha,
                        Name = commit$author$name,
                        When = lubridate::as_datetime(commit$author$when$time)
                    )
                })
                dir_commits$Repository <- fs::path_file(dir)

                return(dir_commits)
            }
        }
    })

    message("Found ", nrow(commits), " commits")

    if (distinct) {
        message("Selecting distinct SHAs...")
        commits <- dplyr::distinct(commits, SHA, .keep_all = TRUE)
        message("Found ", nrow(commits), " distinct commits")
    }

    message("Filtering dates...")
    commits <- dplyr::filter(commits, When >= from)
    message("Found ", nrow(commits), " from ", from)

    if (filter) {
        message("Filtering names...")
        commits <- dplyr::filter(
            commits, Name %in% users
        )
        message("Found ", nrow(commits), " commits by me")
    }

    return(commits)
}
