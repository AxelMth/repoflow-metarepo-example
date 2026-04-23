import { defineConfig } from '@axelmth/repoflow-core'

export default defineConfig({
  repos: [
    {
      name: 'web',
      url: 'https://github.com/axelmth/repoflow-example-web.git',
      prodWorkflow: 'deploy-prod.yml',
    },
    {
      name: 'api',
      url: 'https://github.com/axelmth/repoflow-example-api.git',
      prodWorkflow: 'deploy-prod.yml',
    },
    {
      name: 'shared',
      url: 'https://github.com/axelmth/repoflow-example-shared.git',
      prodWorkflow: 'ci.yml',
    },
  ],
  appsDir: './apps',
  defaultBranch: 'main',
})
