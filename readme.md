# WordPress.org Plugin Attestation

Do you use GitHub Actions to build and deploy your plugin to the WordPress.org Plugin Directory? Add this action to your deployment workflow to generate an attestation for the build provenance of the plugin ZIP file on WordPress.org.

> [!WARNING]
> This action is under development. Version 1.0 will be published when it's considered stable.

This action works well with [the WordPress.org Plugin Deploy action by 10up](https://github.com/10up/action-wordpress-plugin-deploy), but it will work with any workflow which generates a ZIP file of your plugin.

## What is this and why should I use it?

From [the GitHub documentation on artifact attestation](https://docs.github.com/en/actions/security-for-github-actions/using-artifact-attestations/using-artifact-attestations-to-establish-provenance-for-builds):

> Artifact attestations enable you to increase the supply chain security of your builds by establishing where and how your software was built.

This action generates an attestation for the ZIP file that is served by WordPress.org for each release of your plugin. This can subsequently be used by consumers to verify that a given version of your plugin actually originated from your GitHub repo and its deployment workflow.

## Usage

Within the GitHub Actions workflow which deploys your plugin to WordPress.org:

1. Ensure that at least the following permissions are set:

   ```yaml
   permissions:
     id-token: write
     attestations: write
   ```

2. Add the following step to your workflow so it runs after your plugin has been deployed:

   ```yaml
   - uses: johnbillion/attest-wordpress-plugin-build-provenance/@0.2.0
     with:
       plugin: my-plugin-slug
       version: 1.2.3
       zip-path: my-plugin-slug.zip
   ```

> [!WARNING]
> In order to support plugin release confirmation, which is a manual step, this action will attempt to fetch the zip file from WordPress.org for up to 60 minutes. You can adjust this via the `timeout` input parameter.

## Example workflow

```yaml
jobs:
  deploy:
    name: Deploy
    runs-on: ubuntu-latest
    permissions:
      attestations: write
      contents: read
      id-token: write
    timeout-minutes: 70
    steps:
      - name: Deploy plugin to WordPress.org
        uses: 10up/action-wordpress-plugin-deploy@v2
        id: deploy
        env:
          SVN_USERNAME: ${{ secrets.WPORG_SVN_USERNAME }}
          SVN_PASSWORD: ${{ secrets.WPORG_SVN_PASSWORD }}
          VERSION: ${{ inputs.version }}
        with:
          generate-zip: true
      - name: Attest build provenance
        uses: johnbillion/attest-wordpress-plugin-build-provenance/@0.2.0
        with:
          plugin: my-plugin-slug
          version: ${{ inputs.version }}
          zip-path: ${{ steps.deploy.outputs.zip-path }}
```

## Why wouldn't I just generate the attestation directly with `actions/attest-build-provenance`?

This action is specifically for generating an artifact attestation for the ZIP file on the plugin directory on WordPress.org. This facilitates consumers being able to verify attestation for the ZIP file that they download from WordPress.org.

## Does this work if release confirmation is enabled?

The plugin directory on WordPress.org provides a feature called [Release Confirmation](https://developer.wordpress.org/plugins/wordpress-org/release-confirmation-emails/).

This action supports release confirmation because it is designed to retry fetching the plugin ZIP from WordPress.org for up to 60 minutes by default, which allows you time to confirm the release.

## Tip

Set the `timeout-minutes` directive to a little higher than the timeout value of the action, which is 60 minutes by default. This allows some leeway for generating the attestation if you confirm your release right before the timeout is reached. 70 is a reasonable default.

## How do I verify a plugin that publishes attestations?

You need to know the name of the GitHub repo that the plugin was built from, for example `johnbillion/query-monitor`.

Then you can fetch the plugin ZIP at a specific version and attest it using `gh`:

```sh
wget https://downloads.wordpress.org/plugin/query-monitor.3.16.4.zip
gh attestation verify query-monitor.3.16.4.zip --repo johnbillion/query-monitor
```

## Where can I see the attestations for my plugin?

The action will output a link to the attestation within your repo.

You can also view all the attestations from the Attestations link on the Actions screen of your repo.

## Can I call this action within a reusable workflow?

Yes, but be aware that when you verify an attestation you need to use the name of the repo containing the workflow file that performed the attestation. If your reusable workflow lives in a different repo then you'll need to use the name of that repo. If the reusable workflow is in the same repo as your plugin then it's fine.

## License

MIT
