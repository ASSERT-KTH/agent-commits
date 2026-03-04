
We collect traces of agentic commits on Github.

Claude dominates by a large margin.

Notes: this data is unreliable because:
- The Github Search API returns duplicate commits over forks and copied (not forked) repos
- The huge fluctation for Claude shows that the underlying DB of Github does not scale well
Ideally, Github would give us a way to retrieve deduplicated commits

### Date filtering

The query uses `author-date:2020-01-01..<today>` (a range) rather than `committer-date:<=<today>`.

Rationale from empirical testing against the GitHub API:
- Some commits in the index have bogus far-future dates (observed: 2037, 2089) due to misconfigured committer clocks. A plain upper-bound filter (`<=today`) is not sufficient to exclude them — in testing, `author-date:<=today` returned *more* results than no date filter at all, indicating the filter does not reliably act as a ceiling.
- Using an explicit range (`2020-01-01..today`) pins both ends and produces a stable, reproducible count that excludes future-dated commits.
- `author-date` is preferred over `committer-date` because `committer-date` can be updated by merge/rebase operations and does not reflect when the code was originally written.

However, it gives trends.

See also https://github.com/tdegueul/what-are-they-doing

### GraphQL

GitHub's GraphQL API doesn't expose commit search directly. 
The GraphQL `search` type supports issues, PRs, repos, and users but not commits.
So the unreliable REST call is the only tool for the global count.
