# `create-tag`

Composite action that computes the next semver tag for the current repo based on its git history.

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `type` | yes | — | `prerelease` \| `release` \| `hotfix` \| `hotfix-rc` |
| `tag-prefix` | no | `v` | Prefix for all tags |

## Outputs

| Name | Description |
|---|---|
| `tag` | Newly computed tag, e.g. `v1.3.0-rc.2` |
| `prev_tag` | Previous tag used as comparison base, or `none` |
| `rc_tag` | RC tag used as source for a release (only when `type=release`) |
| `hotfix_tags` | Space-separated list of hotfix tags to verify on prereleases |
| `base_prod_tag` | Clean release tag if `prev_tag` was a hotfix |

## Strategy per type

- **prerelease** — bump the active RC number, or start a fresh `minor+1` RC series. Bootstraps to `v0.1.0-rc.1` if the repo has no tags.
- **release** — strip the `-rc.N` suffix from the latest RC tag. Errors if no RC exists.
- **hotfix** — increment patch from the latest production tag.
- **hotfix-rc** — bump the active RC number; if the RC is outdated (already released or older than prod), start a fresh patch RC from prod.

## Usage

```yaml
- uses: ./.github/actions/create-tag
  id: tag
  with:
    type: prerelease
    tag-prefix: v

- run: echo "next tag is ${{ steps.tag.outputs.tag }}"
```
