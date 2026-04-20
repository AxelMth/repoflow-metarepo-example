import { defineConfig } from '@axelmth/repoflow-core'

export default defineConfig({
  repos: [
    {
      name: 'web',
      url: 'https://github.com/axelmth/repoflow-example-web.git',
    },
    {
      name: 'api',
      url: 'https://github.com/axelmth/repoflow-example-api.git',
    },
    {
      name: 'shared',
      url: 'https://github.com/axelmth/repoflow-example-shared.git',
    },
  ],
  appsDir: './apps',
  defaultBranch: 'main',
})
