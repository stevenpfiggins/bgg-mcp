# bgg-mcp - README

Overview
--------
bgg-mcp is a compact Model Context Protocol (MCP) server implemented in TypeScript that exposes BoardGameGeek queries as MCP tools. It uses the MCP SDK, parses BGG's XML APIs with xml2js, and returns human-readable tool responses (search, game details, collections, plays, user info, hot items). The project compiles to `dist/` with TypeScript and includes Docker artifacts for building a production image or running locally for development.

This repo contains a small MCP server implemented in TypeScript. These files let you build and run it inside Docker.

Files added:
- `Dockerfile` - multi-stage build (build with dev deps, runtime with only prod deps)
- `.dockerignore` - files to omit from the build context
- `docker-compose.yml` - convenience compose file to build and run the container

Quick start (build + run using Docker):

```powershell
# Build image
docker build -t bgg-mcp:latest . ;

# Run container
docker run --rm -p 8080:8080 --name bgg-mcp bgg-mcp:latest
```

Or with docker-compose:

```powershell
docker compose up --build
```

Notes
- The project uses the MCP server with stdio transport in `src/index.ts`. By default the server's command in the Docker image runs `node dist/index.js`.
- The container exposes port 8080 (no network server is required for stdio transport). If your MCP runtime requires different transport (stdio vs socket), update the `CMD` in the `Dockerfile` or the source accordingly.
- The Dockerfile installs devDependencies in the build stage so TypeScript can be compiled during image build.

Troubleshooting
- If builds fail due to network or registry issues, try `npm ci` locally to verify and inspect errors.
- To iterate during development, mount the workspace into the container and use `npm run build` or run with `ts-node` inside a dev container.

Available MCP tools
-------------------
This MCP server registers several tools in `src/index.ts`. Each tool returns an MCP-style response object (commonly an object with `content: [{ type: 'text', text: '...' }]`, and optionally `isError: true`). Below are the implemented tools and their inputs:

- `search_games`
	- Purpose: Search BoardGameGeek for board games by free-text query.
	- Inputs: `{ query: string }` (query text)
	- Output: Text summary listing top matches (IDs, names, years) or an error message.

- `get_game_details`
	- Purpose: Fetch detailed information about a game by its BoardGameGeek ID.
	- Inputs: `{ id: string }` (BGG object id)
	- Output: Text block with name, year, players, playing time, min age, average rating and description.

- `get_user_collection`
	- Purpose: Retrieve a user's collection from BoardGameGeek with optional filters.
	- Inputs: `{ username: string, subtype?: string, own?: string, rated?: string, played?: string, rating?: string, maxresults?: number }`
	- Output: Text list of collection items with IDs, names, year, status badges (Owned, Wishlist, etc.) and optional rating info.
	- Notes: The implementation retries when BGG returns 202 (queued) and supports a `maxresults` limit.

- `get_user_plays`
	- Purpose: Get a user's logged plays.
	- Inputs: `{ username: string, mindate?: string, maxdate?: string, id?: string }`
	- Output: Text summary showing recent plays (date, game name/ID, quantity, player count) and totals.

- `get_user_info`
	- Purpose: Fetch public profile information for a BGG user.
	- Inputs: `{ name: string }` (username)
	- Output: Text with username, ID, display name, location, registration year, last login and avatar link.

- `get_hot_items`
	- Purpose: Fetch current hot/trending items on BoardGameGeek.
	- Inputs: `{ type?: string }` (optional item type like `boardgame`)
	- Output: Text listing trending items.

Examples
--------
The MCP tools are designed to be invoked by an MCP host or SDK client. Example tool input payloads (JSON):

`{ "query": "catan" }` for `search_games`

`{ "id": "13" }` for `get_game_details` (replace with a real BGG id)

Implementation note
-------------------
Tool implementations parse XML responses from BoardGameGeek using `xml2js` and return human-readable text blocks. If you need structured JSON outputs for programmatic consumption, we can add JSON shapes or change the return objects to include structured fields in addition to the human text.
