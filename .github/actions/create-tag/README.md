# `create-tag`

Composite action that computes the next production semver tag for the current repo based on its git history.

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `tag-prefix` | no | `v` | Prefix for all tags |

## Outputs

| Name | Description |
|---|---|
| `tag` | Newly computed tag, e.g. `v1.3.0` |
| `prev_tag` | Previous tag used as comparison base, or `none` |

## Strategy

Bumps the minor version from the latest production tag (`vX.Y.Z` → `vX.(Y+1).0`). Bootstraps to `v0.1.0` if the repo has no tags.

## Usage

```yaml
- uses: ./.github/actions/create-tag
  id: tag
  with:
    tag-prefix: v

- run: echo "next tag is ${{ steps.tag.outputs.tag }}"
```
