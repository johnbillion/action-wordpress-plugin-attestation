# WordPress.org Plugin Build Provenance Attestation

Do you use GitHub Actions to build and deploy your plugin to the WordPress.org Plugin Directory? Add this action to your deployment workflow to generate a build provenance attestion for the plugin ZIP file on WordPress.org.

This action works particularly well with [the WordPress.org Plugin Deploy action by 10up](https://github.com/10up/action-wordpress-plugin-deploy), but it will work with any workflow which generates a ZIP file of your plugin.

## Usage

> [!WARNING]
> This action is under development. Version 1.0 will be published when it's considered stable.

Within the GitHub Actions workflow which deploys your plugin to WordPress.org:

1. Ensure that at least the following permissions are set:

   ```yaml
   permissions:
     id-token: write
     attestations: write
   ```

   The `id-token` permission gives the action the ability to mint the OIDC token
   necessary to request a Sigstore signing certificate. The `attestations`
   permission is necessary to persist the attestation.

1. Add the following to your workflow after your plugin has been deployed:

   ```yaml
   - uses: johnbillion/attest-wordpress-plugin-build-provenance/@0.1.1
     with:
       plugin: my-plugin-slug
       version: 1.2.3
       zip-path: my-plugin-slug.zip
   ```

## How do I verify a plugin that publishes attestations?

```
gh attestation verify query-monitor.3.16.4.zip --repo johnbillion/query-monitor
```

## License

MIT
