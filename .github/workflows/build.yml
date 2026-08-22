name: Build Pure CentOS 10 Plasma Bootc Image

on:
  push:
    branches: [ "main" ]
  schedule:
    - cron: "28 20 * * *" # 每天 UTC 20:28 (对应北京时间 CST 04:28)
  workflow_dispatch:

env:
  IMAGE_NAME: my-plasma-lts-vm
  REGISTRY: ghcr.io/${{ github.actor }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      id-token: write # Cosign 签名必需权限

    steps:
      - name: Maximize build space
        uses: ublue-os/remove-unwanted-software@v7

      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install Cosign (Sigstore)
        uses: sigstore/cosign-installer@v3.5.0

      - name: Log into GitHub Container Registry
        uses: redhat-actions/podman-login@v1
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build image using Buildah (Red Hat Standard)
        id: build-image
        uses: redhat-actions/buildah-build@v2
        with:
          image: ${{ env.IMAGE_NAME }}
          tags: latest
          containerfiles: |
            ./Containerfile

      - name: Push to GHCR
        id: push-to-ghcr
        uses: redhat-actions/push-to-registry@v2
        with:
          image: ${{ env.IMAGE_NAME }}
          tags: latest
          registry: ${{ env.REGISTRY }}

      - name: Sign image with Cosign
        env:
          COSIGN_PRIVATE_KEY: ${{ secrets.SIGNING_SECRET }}
        run: |
          cosign sign --yes --key env://COSIGN_PRIVATE_KEY \
            "${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest"
