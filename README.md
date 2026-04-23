# repoflow-metarepo-example

A **meta-repository** that orchestrates three independent repos into a single local development environment — using [`@axelmth/repoflow`](https://www.npmjs.com/package/@axelmth/repoflow).

> A meta-repository is a lightweight orchestrator that doesn't contain source code itself. Instead, it clones and wires together several independent repositories, giving you monorepo-like ergonomics without merging histories or coupling release cycles.

<TODO: link to talk video once published>

Compare this approach with the traditional monorepo: [`repoflow-monorepo-example`](https://github.com/axelmth/repoflow-monorepo-example) — same Hello World app, different architecture.

## Stack

- **pnpm workspaces** — unified dependency management across child repos (after sync)
- **[@axelmth/repoflow](https://www.npmjs.com/package/@axelmth/repoflow)** — CLI for syncing, status, and running commands across repos
- **TypeScript** — for the config file

## Getting started

```bash
# 1. Clone this repo
git clone https://github.com/axelmth/repoflow-metarepo-example.git
cd repoflow-metarepo-example

# 2. Install orchestrator dependencies (just repoflow CLI)
pnpm install

# 3. Clone the 3 child repos into apps/
pnpm sync

# 4. Start web + API dev servers
pnpm dev
```

Visit `http://localhost:5173`. The API runs on `http://localhost:3001`.

Or use the one-shot bootstrap script:

```bash
bash scripts/bootstrap.sh
```

## Child repositories

| Repo | Description |
|---|---|
| [`repoflow-example-web`](https://github.com/axelmth/repoflow-example-web) | React + Vite frontend, cloned to `apps/web` |
| [`repoflow-example-api`](https://github.com/axelmth/repoflow-example-api) | Fastify API, cloned to `apps/api` |
| [`repoflow-example-shared`](https://github.com/axelmth/repoflow-example-shared) | Shared Zod schemas, cloned to `apps/shared` |

## How deployments work

This repo doesn't deploy anything. Each child repo has its own CI/CD:

- `repoflow-example-web` → deploys to **Vercel** on push to `main`
- `repoflow-example-api` → deploys to **Fly.io** on push to `main`

To deploy, push changes directly to the child repos. The metarepo is only for local development orchestration.

## Understanding `repoflow.config.ts`

```ts
import { defineConfig } from '@axelmth/repoflow'

export default defineConfig({
  repos: [
    {
      name: 'web',   // → cloned to apps/web
      url: 'https://github.com/axelmth/repoflow-example-web.git',
      // HTTPS (not SSH) so anyone can clone without SSH keys
    },
    {
      name: 'api',   // → cloned to apps/api
      url: 'https://github.com/axelmth/repoflow-example-api.git',
    },
    {
      name: 'shared', // → cloned to apps/shared
      url: 'https://github.com/axelmth/repoflow-example-shared.git',
    },
  ],
  appsDir: './apps',       // where to clone repos
  defaultBranch: 'main',   // branch to checkout/pull
})
```

After `pnpm sync`, the `apps/` directory contains the 3 cloned repos. The `pnpm-workspace.yaml` picks them up as workspace packages.

## Available commands

```bash
pnpm sync      # clone/pull all child repos
pnpm status    # show git status of each child repo
pnpm doctor    # validate the repoflow config
pnpm dev       # start web + API dev servers
pnpm build     # build all child repos
pnpm test      # test all child repos
pnpm lint      # lint all child repos
```

## Release workflow

This meta-repo also ships a **production-grade release workflow** that runs against each child repo from a single place. It relies on one optional field in `repoflow.config.ts`:

```ts
{
  name: 'api',
  url: 'https://github.com/axelmth/repoflow-example-api.git',
  prodWorkflow: 'deploy-prod.yml', // workflow triggered on stable tag
}
```

`prodWorkflow` is **optional**. `sync`, `status` and `doctor` don't need it — only the release workflow does.

### The workflow

| Workflow | When to use | How to trigger | What it does |
|---|---|---|---|
| **Release** | Ship to prod | `Actions → Release → Run workflow` | • Bumps minor from latest prod tag<br>• Creates a **DRAFT** GitHub Release targeting `HEAD`<br>• Human review + publish triggers the prod deploy |

The workflow accepts a `dry-run` input that skips releases and Slack posts — useful when testing a new child repo.

### 2-level pipeline

The design separates **tagging** (owned by this meta-repo) from **deployment** (owned by each child repo):

1. The meta-repo creates a **draft** GitHub Release on the child repo, targeting `HEAD`.
2. A human reviews and publishes the draft — GitHub creates the tag at that moment.
3. The child repo's own workflow (e.g. `deploy-prod.yml`) is triggered by the tag push and handles the actual build + deploy.

This keeps each child repo self-contained (it knows how to deploy itself) while centralizing tag/changelog/Slack orchestration. <TODO: link to talk slides once available>

### Required GitHub secrets

| Secret | Purpose |
|---|---|
| `GIT_PAT_PULL` | PAT with `repo` scope — used to checkout, tag, and release child repos |
| `GIT_PAT` | PAT with `repo` scope — used by `wait-for-workflows.sh` to poll child repo runs |
| `SLACK_BOT_TOKEN` | Slack bot OAuth token (`xoxb-...`) — used by `notify-slack` |
| `SLACK_CHANGELOG_CHANNEL_ID` | Channel ID for `#changelog` |

`GIT_PAT_PULL` and `GIT_PAT` can point at the same token. They're split in the config so you can rotate or scope them independently if needed.

### Shared composite actions

The `.github/actions/` folder contains three composite actions that the workflows use. They're also designed to be **injected** into child repos at runtime (the workflows `cp -R` them into the checkout) so child repos don't have to duplicate them:

- [`create-tag`](.github/actions/create-tag) — computes the next semver tag
- [`notify-slack`](.github/actions/notify-slack) — posts a Block Kit message to Slack
- [`release-flow`](.github/actions/release-flow) — orchestrates tag + release + Slack

Each folder has its own README with inputs, outputs, and usage.

### Customization points

- **Swap the notification transport** (Teams, Discord, email…) — replace the inline Node script in `.github/actions/notify-slack/action.yml`. Keep the same inputs and no workflow needs to change.
- **Different tag prefix** — pass `tag-prefix` to `create-tag` (defaults to `v`).
- **Filter which repos get released** — trigger the workflow manually with `repos: web,api` (comma-separated).

## Troubleshooting

**`pnpm dev` fails with "apps/web not found"**
Run `pnpm sync` first to clone the child repos.

**`pnpm sync` fails with authentication error**
The repos use HTTPS URLs (not SSH). Make sure you have internet access. If you've forked the repos, update the URLs in `repoflow.config.ts`.

**Node version mismatch**
This project requires Node 20+. Check with `node --version`. Use [nvm](https://github.com/nvm-sh/nvm) or [fnm](https://github.com/Schniz/fnm) to switch versions.

**Port already in use**
The API uses port 3001 and the web dev server uses 5173. Kill any processes using those ports:
```bash
lsof -ti:3001 | xargs kill
lsof -ti:5173 | xargs kill
```

---

Part of the **repoflow-examples** collection:
- [`repoflow-monorepo-example`](https://github.com/axelmth/repoflow-monorepo-example) — same app as a Turborepo monorepo
- [`repoflow-example-web`](https://github.com/axelmth/repoflow-example-web) — React frontend
- [`repoflow-example-api`](https://github.com/axelmth/repoflow-example-api) — Fastify backend
- [`repoflow-example-shared`](https://github.com/axelmth/repoflow-example-shared) — shared Zod schemas
