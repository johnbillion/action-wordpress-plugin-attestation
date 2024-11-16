# WordPress.org Plugin Build Provenance Attestation

Do you use GitHub Actions to build and deploy your plugin to the WordPress.org Plugin Directory? Add this action to your deployment workflow to generate a build provenance attestation for the plugin ZIP file on WordPress.org.

> [!WARNING]
> This action is under development. Version 1.0 will be published when it's considered stable.

This action works well with [the WordPress.org Plugin Deploy action by 10up](https://github.com/10up/action-wordpress-plugin-deploy), but it will work with any workflow which generates a ZIP file of your plugin.

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
   - uses: johnbillion/attest-wordpress-plugin-build-provenance/@0.1.1
     with:
       plugin: my-plugin-slug
       version: 1.2.3
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
          VERSION: ${{ inputs.version }}
        with:
          generate-zip: true
      - name: Attest build provenance
        uses: johnbillion/attest-wordpress-plugin-build-provenance/@0.1.1
        with:
          plugin: my-plugin-slug
          version: ${{ inputs.version }}
          zip-path: ${{ steps.deploy.outputs.zip-path }}
```

## How do I verify a plugin that publishes attestations?

You need to know the name of the GitHub repo that the plugin was built from, for example `johnbillion/query-monitor`.

Then you can fetch the plugin zip at a specific version and attest it using `gh`:

```sh
wget https://downloads.wordpress.org/plugin/query-monitor.3.16.4.zip
gh attestation verify query-monitor.3.16.4.zip --repo johnbillion/query-monitor
```

## License

MIT
