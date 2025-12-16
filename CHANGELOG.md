# CHANGELOG

<!-- version list -->

## v3.3.1 (2025-12-16)

### Bug Fixes

- Trying to deploy to Lambda direcly (zip).
  ([`edce196`](https://github.com/marq4/RandomVideoClipGenerator-Streamer/commit/edce196dc3b79b675797fa4022af36ba578ff24b))


## v3.3.0 (2025-12-16)

### Bug Fixes

- Trying to confirm that if Release job needs code-testing, AND testing is skipped, then Release is
  ALSO SKIPPED (doesn't even evaluate the if: conditions) [skiptest].
  ([`a467d00`](https://github.com/marq4/RandomVideoClipGenerator-Streamer/commit/a467d006146d2a1b08fdd1ad03bb38b65085bcd9))

### Features

- Expected: tests skipped, Release runs (v3.3.0), deploy to Lambda fails. [skiptest].
  ([`7a5489d`](https://github.com/marq4/RandomVideoClipGenerator-Streamer/commit/7a5489db38eb99a430998cd24677e8e5d3a7557a))


## v3.2.0 (2025-12-16)

### Features

- Testing deploy to Lambda (running tests).....
  ([`b2246b3`](https://github.com/marq4/RandomVideoClipGenerator-Streamer/commit/b2246b3137f418b3b21e77082bf6d32520926ab8))

- Testing deploy to Lambda [skiptest].
  ([`14c053e`](https://github.com/marq4/RandomVideoClipGenerator-Streamer/commit/14c053e830e2424fbba2ed078f150c1cdb78975c))

- Testing deploy to lambda [skiptest].
  ([`fcd4a4a`](https://github.com/marq4/RandomVideoClipGenerator-Streamer/commit/fcd4a4aaa6f9ca86d23fa1b85862544006bf8ca8))

- Testing deploy to lambda [skiptest]. YAML lint.
  ([`e984216`](https://github.com/marq4/RandomVideoClipGenerator-Streamer/commit/e98421647a818d38a2b679bf3b1915a51943fcfd))

- Testing deploy to Lambda [skiptest]..
  ([`7f16851`](https://github.com/marq4/RandomVideoClipGenerator-Streamer/commit/7f1685147a67dffdaac0ccbd8a75c151c6aa78b2))

- Testing deploy to Lambda [skiptest]...
  ([`c21e45a`](https://github.com/marq4/RandomVideoClipGenerator-Streamer/commit/c21e45a634ae17bf811feded73a54ea34fd14fab))

- Testing deploy to Lambda [skiptest]....
  ([`c816630`](https://github.com/marq4/RandomVideoClipGenerator-Streamer/commit/c816630f6d9ed95cc30c7e9979a10b57594b02f6))

- Testing deploy to Lambda [skiptest].....
  ([`395915c`](https://github.com/marq4/RandomVideoClipGenerator-Streamer/commit/395915c9893fe6464945b5fa732fa3886c966fed))


## v3.1.0 (2025-12-15)

### Features

- Fixing import boto3 during Release.
  ([`2e8af04`](https://github.com/marq4/RandomVideoClipGenerator-Streamer/commit/2e8af044cc438a3e0de42de49f80459931ae885a))


## v3.0.0 (2025-12-15)

### Features

- Consolidated code and separated functions into common, local, cloud. Testing release: 2.1.0.
  ([`05d38ec`](https://github.com/marq4/RandomVideoClipGenerator-Streamer/commit/05d38ec4eb609f681797a854c8ef77ccabf33d7d))


## v2.0.1 (2025-12-10)


## v2.0.0 (2025-12-09)

### Features

- Expected Release to be: 2.0.0. Added job to CICD workflow: Release.
  ([`07cdfdb`](https://github.com/marq4/RandomVideoClipGenerator-Streamer/commit/07cdfdb6ae68cac0b2d0eebafd4ec021e8401ac3))


## v1.4.0 (2025-12-08)

- Initial Release
