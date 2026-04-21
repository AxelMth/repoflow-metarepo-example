# `notify-slack`

Composite action that posts a Block Kit formatted message to Slack via `chat.postMessage`.

## Inputs

| Name | Required | Description |
|---|---|---|
| `slack-token` | yes | Slack bot token (`xoxb-...`) |
| `channel-id` | yes | Target channel ID |
| `title` | yes | Header text |
| `body` | yes | Body (Slack mrkdwn) |
| `url` | no | Optional URL rendered as a primary button |

## Usage

```yaml
- uses: ./.github/actions/notify-slack
  with:
    slack-token: ${{ secrets.SLACK_BOT_TOKEN }}
    channel-id: ${{ secrets.SLACK_CHANGELOG_CHANNEL_ID }}
    title: "🚀 Release v1.3.0"
    body: "*api* deployed to production\n• commit `abc123`"
    url: https://github.com/org/api/releases/tag/v1.3.0
```

## Swapping the transport

To swap Slack for Teams, Discord, etc., replace the inline Node script in `action.yml` with your webhook call. Keep the same inputs — workflows don't need to change.
