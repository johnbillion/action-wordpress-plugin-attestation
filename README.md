# WordPress Plugin Attestation

Do you use GitHub Actions to build and deploy your plugin to the WordPress.org Plugin Directory? Add this action to your deployment workflow to generate an attestation for the build provenance of the plugin ZIP file on WordPress.org.

This action integrates well with [the WordPress Plugin Deploy action by 10up](https://github.com/marketplace/actions/wordpress-plugin-deploy), but it will work with any workflow which can generate a ZIP file of your plugin.

## What is this and why should I use it?

From [the GitHub documentation on artifact attestation](https://docs.github.com/en/actions/security-for-github-actions/using-artifact-attestations/using-artifact-attestations-to-establish-provenance-for-builds):

> Artifact attestations enable you to increase the supply chain security of your builds by establishing where and how your software was built.

This action generates an attestation for the ZIP file that is served by WordPress.org for each release of your plugin. This can subsequently be used by consumers to verify that a given version of your plugin actually originated from your GitHub repo and its deployment workflow.

There is not much tooling for the verification aspect at the moment, but in the future this can facilitate verifying that a plugin release came from its trusted author rather than an unwanted entity, for example somebody who stole your wordpress.org svn password, hacked into wordpress.org, or performed a hostile plugin takeover.

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
   - uses: johnbillion/action-wordpress-plugin-attestation@0.5.0
     with:
       zip-path: my-plugin-slug.zip
   ```

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
        with:
          generate-zip: true
      - name: Attest build provenance
        uses: johnbillion/action-wordpress-plugin-attestation@0.5.0
        with:
          zip-path: ${{ steps.deploy.outputs.zip-path }}
```

## Inputs

Here is the full list of required and optional inputs:

```yaml
- uses: johnbillion/action-wordpress-plugin-attestation@0.5.0
  with:
    # Required. Path to the ZIP file generated for the plugin release.
    # Use `${{ steps.deploy.outputs.zip-path }}` if you're using the WordPress Plugin Deploy action by 10up.
    zip-path: my-plugin-slug.zip

    # Optional. Plugin slug name. Defaults to the repo name.
    plugin: my-plugin-slug

    # Optional. Plugin version number. Defaults to the tag name if triggered by pushing a tag or a release.
    version: 1.2.3

    # Optional. Maximum time in minutes to spend trying to fetch the ZIP from WordPress.org.
    timeout: 60

    # Optional. Whether to perform a dry-run which runs everything except the actual attestation step.
    dry-run: false
```

## Why wouldn't I just generate the attestation directly with `actions/attest-build-provenance`?

This action is specifically for generating an artifact attestation for the ZIP file on the plugin directory on WordPress.org. This facilitates consumers being able to verify attestation for the ZIP file that they download from WordPress.org.

## Does this work if release confirmation is enabled?

Yes, this action supports [plugin release confirmation](https://developer.wordpress.org/plugins/wordpress-org/release-confirmation-emails/) because it will repeatedly attempt to fetch the plugin ZIP from WordPress.org for up to 60 minutes by default, which allows you time to confirm the release.

## Tip

Set the `timeout-minutes` directive to a little higher than the timeout value of the action, which is 60 minutes by default. This allows some leeway for generating the attestation if you confirm your release right before the timeout is reached. 70 is a reasonable default.

## How do I verify a plugin that publishes attestations?

You need to know the name of the GitHub repo that the plugin was built from, for example `johnbillion/query-monitor`.

Then you can fetch the plugin ZIP at a specific version and attest it using `gh`:

```sh
wget https://downloads.wordpress.org/plugin/query-monitor.3.16.4.zip
gh attestation verify query-monitor.3.16.4.zip --repo johnbillion/query-monitor
```

## How can I test this action without doing a release?

Create a `workflow_dispatch` workflow that calls the `johnbillion/action-wordpress-plugin-attestation` action with the zip file of your plugin. You can then run this workflow against a branch or tag of your choice. Optionally use the `dry-run` parameter to perform all the verification steps without publishing the attestation.

<details>
  <summary>Example workflow:</summary>

  ```yaml
  name: Test attestation

  on:
    workflow_dispatch:

  jobs:
    deploy:
      name: Test attestation
      runs-on: ubuntu-latest
      permissions:
        attestations: write
        contents: read
        id-token: write
      steps:
        - name: Build the plugin zip file without deploying to WordPress.org
          uses: 10up/action-wordpress-plugin-deploy@v2
          id: deploy
          with:
            generate-zip: true
            dry-run: true
        - name: Attest build provenance
          uses: johnbillion/action-wordpress-plugin-attestation@v0.5.0
          with:
            zip-path: ${{ steps.deploy.outputs.zip-path }}
            dry-run: true # Remove this to publish the attestation
  ```
</details>

## How do I re-run attestation if the action times out before I confirm the release on WordPress.org?

See above.

## Where can I see the attestations for my plugin?

The action will output a link to the attestation.

You can also view all attestations from the Actions -> Attestations screen in your repo.

## Can I call this action within a reusable workflow?

Yes, but be aware that when a consumer uses `gh attestation verify` or any other tool to verify an attestation _they need to use the name of the repo that contains the workflow file that performed the attestation_. If the reusable workflow is in the same repo as your plugin then there's no problem, but if your reusable workflow lives in a different repo then they'll need to know and use the name of that repo during verification.

## TODO

* Add support for arbitrary remote hosts in addition to wordpress.org
* Consider how attestations can be used as part of workflows for installing and deploying plugins
  - WP-CLI
  - Composer, Packagist, WPackagist
* Sigstore, Cosign, Rekor, SLSA, SBOM, OpenSSF Scorecard...

## License

MIT
