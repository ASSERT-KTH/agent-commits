
We collect traces of agentic commits on Github.

Claude dominates by a large margin.

Notes: this data is unreliable because:
- The Github Search API returns duplicate commits over forks and copied (not forked) repos
- The huge fluctation for Claude shows that the underlying DB of Github does not scale well
Ideally, Github would give us a way to retrieve deduplicated commits

However, it gives trends.

See also https://github.com/tdegueul/what-are-they-doing

### GraphQL

GitHub's GraphQL API doesn't expose commit search directly. 
The GraphQL `search` type supports issues, PRs, repos, and users but not commits.
So the unreliable REST call is the only tool for the global count.
