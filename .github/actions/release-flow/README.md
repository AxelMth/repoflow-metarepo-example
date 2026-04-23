# `release-flow`

The heart of the release logic. Orchestrates tag computation, draft release creation, and Slack notification.

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `repository` | yes | — | Full repo name, `owner/repo` |
| `github-token` | yes | — | PAT with `repo` scope |
| `slack-token` | yes | — | Slack bot token |
| `channel-id` | yes | — | Slack channel ID |
| `dry-run` | no | `false` | Simulate without creating the draft release or posting to Slack |

## Outputs

| Name | Description |
|---|---|
| `tag` | Computed tag (or would-be tag in dry-run) |
| `prev_tag` | Previous tag |
| `skipped` | `'true'` if there are no new commits since `prev_tag` |
| `commit_hash` | SHA of the tagged commit |
| `tag_pushed_at` | ISO timestamp of the release creation |

## Flow

1. Compute next tag via `create-tag`
2. Verify there are new commits (else skip cleanly)
3. Generate release notes from commits between `prev_tag..HEAD`
4. Create a **DRAFT** GitHub Release targeting `HEAD` (the tag is created on publish)
5. Post to Slack via `notify-slack`

## Dry-run mode

When `dry-run: 'true'`, no release is created and no Slack message is posted. The computed tag is still returned as an output so you can inspect what *would* have happened.
