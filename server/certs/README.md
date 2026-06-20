# Certificates

To enable App Store receipt validation (`APPSTORE_VERIFY=on`), download the
**Apple Root CA - G3** certificate (PEM) and place it here as
`AppleRootCA-G3.pem`:

- https://www.apple.com/certificateauthority/  → "Apple Root CA - G3 Root"

This is Apple's public root that signs StoreKit 2 transactions. The path is
configurable via `APPLE_ROOT_CA_PATH`. With validation off (dev/simulator), no
certificate is needed.
