## Installation

**Run the local script**
```bash
sudo mkdir -p /opt/aicuda/acumen
cd /opt/aicuda/acumen
sudo wget https://raw.githubusercontent.com/Aicuda/Acumen/refs/heads/main/install.sh
sudo chmod +x install.sh
sudo sh install.sh
```

**Run the script from the remote**
```bash
curl -fsSL https://raw.githubusercontent.com/Aicuda/Acumen/refs/heads/main/install.sh | sudo sh
```

## Installing a specific version

By default the installer installs the `latest` version. Set `IMAGE_TAG` to install another version:

```bash
curl -fsSL https://raw.githubusercontent.com/Aicuda/Acumen/refs/heads/main/install.sh | sudo IMAGE_TAG=1.2.0 sh
```

To upgrade or switch versions, run the installer again with the new `IMAGE_TAG`. It replaces the containers and keeps the configuration and data in `PRODUCT_HOME`. Pass the same options as the first installation, such as `OEM` and `IMAGE_PREFIX`: the installer does not remember them, and without `OEM` an OEM installation is replaced by the non-OEM acumen-ms.

If an image of that version can't be found, the installer stops before it touches the running containers.

Before installing an older version, check the database: acumen-as writes no results while the database schema is newer than the version installed.

**Releasing a version**

A version is installable only when acumen-ms, acumen-as and acumen-ss all have images tagged with it. Push the same git tag, e.g. `1.2.0`, to the Acumen-MS, Acumen-AS and Acumen-SS repositories; each pipeline publishes its image with that tag. For an OEM, also run the Acumen-MS pipeline for that tag with the variable `OEM=<oem>`, which publishes `acumen-ms-<oem>:<tag>`.

## Options

Options are environment variables. Put them after `sudo`: `sudo` resets the environment, so variables set before it are dropped.

```bash
sudo IMAGE_PREFIX=192.168.0.5:5000/aicuda IMAGE_TAG=1.2.0 sh install.sh
```

| Variable | Default | Description |
|---|---|---|
| `IMAGE_PREFIX` | `quay.io/aicuda` | Registry and namespace to pull the images from. |
| `IMAGE_TAG` | `latest` | Acumen version to install, used as the tag of the acumen-ms, acumen-as and acumen-ss images. |
| `MS_IMAGE_TAG`, `AS_IMAGE_TAG`, `SS_IMAGE_TAG` | from `IMAGE_TAG` | Version of one image, to run it at a different version from the others. Overrides `IMAGE_TAG`. |
| `MS_IMAGE`, `AS_IMAGE`, `SS_IMAGE` | `<IMAGE_PREFIX>/<PRODUCT_NAME>-ms[-<OEM>]:<MS_IMAGE_TAG>`, and so on | Full reference of one image. Overrides the prefix and the tag. |
| `OEM` | empty | OEM build to install. See [OEM installation](#oem-installation). |
| `LICENSE_PRODUCT` | from `OEM` | License product of acumen-as, passed to it as `ACUMEN_LICENSE_PRODUCT`. Overrides the one `OEM` sets. |
| `PRODUCT_HOME` | `/opt/aicuda/acumen` | Host directory for configuration, data, logs and the generated `compose.yaml`. |
| `PRODUCT_NAME` | `acumen` | Prefix of the image names and the container names. |
| `MS_HOST`, `AS_HOST`, `SS_HOST` | this machine | Address of the machine running acumen-ms, acumen-as or acumen-ss. |
| `TIMESCALEDB_IMAGE` | set in the acumen-ms compose file | TimescaleDB image. |

## OEM installation

Set `OEM` to install an OEM build. Supported values: `anasystem`.

```bash
curl -fsSL https://raw.githubusercontent.com/Aicuda/Acumen/refs/heads/main/install.sh | sudo IMAGE_TAG=1.2.0 OEM=anasystem sh
```

Only acumen-ms has OEM images. `OEM` changes two things:

- acumen-ms is pulled from the OEM's own repository, `acumen-ms-<OEM>`, with the same `IMAGE_TAG`: `acumen-ms-anasystem:latest`, or `acumen-ms-anasystem:1.2.0` with `IMAGE_TAG=1.2.0`. acumen-as and acumen-ss are the same images as for a non-OEM installation.
- The generated `compose.yaml` sets `ACUMEN_LICENSE_PRODUCT` on the acumen-as container, which uses it as its `license_product`. A `license_product` in `etc/system.json` still wins over it.

  | `OEM` | `ACUMEN_LICENSE_PRODUCT` |
  |---|---|
  | empty | not set; acumen-as uses `license_product` in `etc/system.json` (default `PRODUCT_ACUMEN`) |
  | `anasystem` | `PRODUCT_ACUMEN_ANASYSTEM` |

Keep `PRODUCT_NAME=acumen` for an OEM installation. The image names are built from it, and there are no `anasystem-as` or `anasystem-ss` images.

The license file must be issued for the OEM's license product and imported as that product.

**Adding an OEM**

1. Publish acumen-ms images for the OEM as `acumen-ms-<oem>`: run the Acumen-MS pipeline with the variable `OEM=<oem>`.
2. In `install.sh`, add the OEM to the `case "$OEM"` block with its license product, a value of the `Product` enum in license-service `protos/enums.proto`.
3. Add the OEM to the table above.
