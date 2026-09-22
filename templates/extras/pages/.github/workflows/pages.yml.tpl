# Deploy the HTML study hub (site/) to GitHub Pages.
# Source of truth for narrative browsing; graded work stays on __LMS__.
#
# After first enable in repo Settings → Pages → Source: GitHub Actions,
# student URL is typically:
#   __PAGES_URL__

name: Deploy GitHub Pages

on:
  push:
    branches: [worx, main]
    paths:
      - "site/**"
      - "scripts/build-pages.sh"
      - ".github/workflows/pages.yml"
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build static site
        env:
          PAGES_BLOB_BRANCH: ${{ github.ref_name }}
        run: bash scripts/build-pages.sh

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: _site

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
