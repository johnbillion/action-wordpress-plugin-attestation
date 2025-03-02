# WordPress Plugin Attestation

Do you use GitHub Actions to deploy your plugin to the WordPress.org plugin directory? Add this action to your deployment workflow to generate a [build provenance attestation](https://docs.github.com/en/actions/security-for-github-actions/using-artifact-attestations/using-artifact-attestations-to-establish-provenance-for-builds) of the plugin ZIP file on WordPress.org.

This action integrates well with [the WordPress Plugin Deploy action](https://github.com/marketplace/actions/wordpress-plugin-deploy), but it can work with any workflow which deploys your plugin.

## What is this and why should I use it?

<blockquote>
	<p>Artifact attestations enable you to increase the supply chain security of your builds by establishing where and how your software was built.</p>
	<p><cite><a href="https://docs.github.com/en/actions/security-for-github-actions/using-artifact-attestations/using-artifact-attestations-to-establish-provenance-for-builds">Source: GitHub Docs</a></cite></p>
</blockquote>

This action generates an artifact attestation for the ZIP file that is served by the plugin directory for each release of your plugin. This can subsequently be used by consumers to verify that a given version of your plugin actually originated from your user account on GitHub.

There is not much tooling for the verification aspect at the moment — other than the `gh attestation verify` command — but this ultimately facilitates verifying that a plugin release came from its trusted author rather than an unwanted entity, for example somebody who stole your SVN password, hacked into WordPress.org, or performed a hostile plugin takeover.

## Usage

Within the GitHub Actions workflow which deploys your plugin to the plugin directory:

1. Ensure that at least the following permissions are set:

   ```yaml
   permissions:
     id-token: write
     attestations: write
   ```

2. Add the following step to your workflow so it runs after your plugin has been deployed:

   ```yaml
   - uses: johnbillion/action-wordpress-plugin-attestation@0.7.0
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
      - name: Deploy to the plugin directory
        uses: 10up/action-wordpress-plugin-deploy@v2
        id: deploy
        env:
          SVN_USERNAME: ${{ secrets.WPORG_SVN_USERNAME }}
          SVN_PASSWORD: ${{ secrets.WPORG_SVN_PASSWORD }}
        with:
          generate-zip: true
      - name: Generate build provenance attestation
        uses: johnbillion/action-wordpress-plugin-attestation@0.7.0
        with:
          zip-path: ${{ steps.deploy.outputs.zip-path }}
```

## Inputs

Here is the full list of required and optional inputs:

```yaml
- uses: johnbillion/action-wordpress-plugin-attestation@0.7.0
  with:
    # Required. Path to the ZIP file generated for the plugin release.
    # Use `${{ steps.deploy.outputs.zip-path }}` if you're using the
    # "WordPress.org Plugin Deploy" action.
    zip-path: my-plugin-slug.zip

    # Optional. Plugin slug name. Default is the repo name.
    plugin: my-plugin-slug

    # Optional. Plugin version number. Default is the tag name if
    # triggered by pushing a tag or creating a release.
    version: 1.2.3

    # Optional. Maximum time in minutes to spend trying to fetch the
    # ZIP from the plugin directory. Default is 60.
    timeout: 60

    # Optional. Whether to perform a dry run which runs everything
    # except for generating the actual attestation. Default false.
    dry-run: false

    # Optional. The URL where the plugin ZIP file is hosted (for
    # platforms other than WordPress.org). Default is the URL of
    # the ZIP file on the WordPress.org plugin directory.
    zip-url: 'https://example.com/%plugin%-%version%.zip'
```

## Outputs

| Name              | Description                                                    | Example                                                |
| ----------------- | -------------------------------------------------------------- | ------------------------------------------------------ |
| `attestation-id`  | GitHub ID for the attestation                                  | `123456`                                               |
| `attestation-url` | URL for the attestation summary                                | `https://github.com/foo/bar/attestations/123456`       |
| `bundle-path`     | Absolute path to the file containing the generated attestation | `/tmp/attestation.json`                                |
| `zip-url`         | URL where the plugin ZIP file is hosted                        | `https://downloads.wordpress.org/plugin/foo.1.2.3.zip` |

## Can't I just use `actions/attest-build-provenance`?

This action is a wrapper for the `actions/attest-build-provenance` action provided by GitHub. It specifically handles generating an attestation for the ZIP file of your plugin once it's been deployed to the plugin directory. This facilitates consumers being able to verify the provenance of the ZIP file that they download from WordPress.org, not just for an artifact on GitHub.

## Does this work if my plugin has a build step?

Yes, this action supports plugins that have a build step because it is only concerned about whatever you commit to the plugin directory. Just call this action with a ZIP of those files and you're good to go.

## Does this work if release confirmation is enabled?

Yes, this action specifically supports [plugin release confirmation](https://developer.wordpress.org/plugins/wordpress-org/release-confirmation-emails/). It will periodically attempt to fetch the plugin ZIP from the plugin directory for up to 60 minutes, which allows you plenty of time to confirm the release.

> [!TIP]
> Set the `timeout-minutes` directive to a little higher than the `timeout` input of the action, which is 60 minutes by default. This allows some leeway for generating the attestation if you confirm your release right before the timeout is reached. 70 is a reasonable value.

## Does this work for hosts other than WordPress.org?

Yes, this action supports hosts other than WordPress.org in case you want to generate an attestation for a ZIP file that you deploy elsewhere. The `zip-url` input can be used to specify a custom ZIP URL to fetch and attest. These dynamic value placeholders can be used within the URL:

* `%plugin%` for the plugin slug
* `%version%` for the version number

The default ZIP URL is `https://downloads.wordpress.org/plugin/%plugin%.%version%.zip`.

If you deploy your plugin to multiple locations, call this action once for each.

## How do I verify a plugin that publishes attestations?

At a minimum you need to know the name of the owner of the repo that the plugin was built from, for example `johnbillion`.

Then you can fetch the plugin ZIP file at a specific version and verify its provenance using the `gh` command:

### Verify provenance using the owner name

The `--owner` option works regardless of whether or not the plugin uses a reusable workflow for its deployment:

```sh
wget https://downloads.wordpress.org/plugin/query-monitor.3.16.4.zip
gh attestation verify query-monitor.3.16.4.zip \
  --owner johnbillion
```

### Verify provenance using the repo name

The `--repo` option only works only if the plugin is not using a reusable workflow for its deployment:

```sh
wget https://downloads.wordpress.org/plugin/query-monitor.3.16.4.zip
gh attestation verify query-monitor.3.16.4.zip \
  --repo johnbillion/query-monitor
```

### Verify provenance using the repo name and signer repo name

The combined `--repo` and `--signer-repo` options work if the plugin uses a reusable workflow for its deployment:

```sh
wget https://downloads.wordpress.org/plugin/query-monitor.3.16.4.zip
gh attestation verify query-monitor.3.16.4.zip \
  --repo johnbillion/query-monitor \
  --signer-repo johnbillion/plugin-infrastructure
```

## How can I test this action without doing a release?

Create a `workflow_dispatch` workflow that calls the `johnbillion/action-wordpress-plugin-attestation` action with the zip file of your plugin. You can then run this workflow against a branch or tag of your choice from the Actions screen of your repo.

Optionally use the `dry-run` parameter to perform all the verification steps without publishing the attestation.

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
        - name: Build the plugin zip file without deploying it
          uses: 10up/action-wordpress-plugin-deploy@v2
          id: deploy
          with:
            generate-zip: true
            dry-run: true
        - name: Generate build provenance attestation
          uses: johnbillion/action-wordpress-plugin-attestation@0.7.0
          with:
            zip-path: ${{ steps.deploy.outputs.zip-path }}
            dry-run: true # Remove this to publish the attestation
  ```
</details>

## How do I regenerate an attestation if the action times out before I confirm the release?

See above.

## What SLSA level does this facilitate?

To the best of my understanding, build provenance attestation on GitHub [facilitates adhering to SLSA v1.0 Build Level 2](https://slsa.dev/spec/v1.0/levels).

Adhering to SLSA v1.0 Build Level 3 requires that [the build runs in an isolated environment](https://slsa.dev/spec/v1.0/requirements#isolated). One way to do this is to [use a reusable workflow to perform the build, deployment, and attestation generation](https://docs.github.com/en/actions/security-for-github-actions/using-artifact-attestations/using-artifact-attestations-and-reusable-workflows-to-achieve-slsa-v1-build-level-3), but there are additional considerations such as not using caching during the build and deployment process.

## Where can I see the attestations for my plugin?

The action will output a link to the attestation.

You can also view all attestations from the Actions -> Attestations screen in your repo.

## Can I call this action within a reusable workflow?

Yes, but be aware that when a consumer uses `gh attestation verify` to verify an attestation they need to be aware of which option(s) they need to provide to the command depending on whether a reusable workflow was used to deploy the plugin. See the [How do I verify a plugin that publishes attestations?](#how-do-i-verify-a-plugin-that-publishes-attestations) section above for all the details.

## Sponsors

The time that I spend maintaining this library and others is in part sponsored by:

[![Automattic](https://cdn.jsdelivr.net/gh/johnbillion/johnbillion/assets/sponsors/automattic.png)](https://automattic.com)

Plus all my kind sponsors on GitHub:

[![Sponsors](https://cdn.jsdelivr.net/gh/johnbillion/johnbillion/sponsors.svg)](https://github.com/sponsors/johnbillion)

[Click here to find out about supporting this library and my other WordPress development tools and plugins](https://github.com/sponsors/johnbillion).

## License

MIT
