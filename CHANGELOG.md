# Changelog

## 1.0.0 (2025-04-15)


### ⚠ BREAKING CHANGES

* change `path_to_love` to `path_to_love_bin`
* minimal init in Lua with lspconfig
* add LSP config using lspconfig plugin
* better handling of pending jobs

### Features

* add `LoveStop` user commnad ([4000183](https://github.com/S1M0N38/love2d.nvim/commit/400018368b9d5397574be9c6774347d8d6bf5b0a))
* add config module with extentible defaults ([e68d1bc](https://github.com/S1M0N38/love2d.nvim/commit/e68d1bc0b318d8034d3f871200e88286076a7627))
* add init.lua ([0a52201](https://github.com/S1M0N38/love2d.nvim/commit/0a522015e9c01196862bd22fcb3aec3c9dccbe44))
* add LSP config using lspconfig plugin ([7a76d92](https://github.com/S1M0N38/love2d.nvim/commit/7a76d9281f7bd88d30829bbb2b07fe3610e471c8))
* add shaders example to test/game ([c5cd04f](https://github.com/S1M0N38/love2d.nvim/commit/c5cd04fa1fc97c1eed50d8d58ce7d9e8295f6650))
* add stop function for stopping running project ([fde9cf3](https://github.com/S1M0N38/love2d.nvim/commit/fde9cf36bfcad5aa3b242f81adcb0719b1a077f8))
* avoid running new job if one is already running ([787bf0d](https://github.com/S1M0N38/love2d.nvim/commit/787bf0d89a92ebed120a3c3e3ed24b5b259bc9b8))
* **config:** add option to restart LÖVE on file save ([6689ac3](https://github.com/S1M0N38/love2d.nvim/commit/6689ac3812e29497c8aa6dc27e8f0e25a12054c2))
* move notification for main.lua not found into user cmd ([00229e7](https://github.com/S1M0N38/love2d.nvim/commit/00229e73e3ba39b12904b68606c451b1be9ab0ed))
* **tests:** add simple example game ([58b698b](https://github.com/S1M0N38/love2d.nvim/commit/58b698b0f6d23126f4600420f4ad8ebde21fc8c2))
* **tests:** add tests for stop function ([4da48c3](https://github.com/S1M0N38/love2d.nvim/commit/4da48c3aecfe2634a0e89a5dbd7dc38edb5e509c))
* **tests:** Love starts and run project ([276c2e9](https://github.com/S1M0N38/love2d.nvim/commit/276c2e98729e68fdef454e330a120931fe9cde99))
* **treesitter:** add injections of glsl ([f053933](https://github.com/S1M0N38/love2d.nvim/commit/f05393381d3bf3ac4f3fe3df940df088d87f3c39))
* user command `LoveRun` ([b80d2c7](https://github.com/S1M0N38/love2d.nvim/commit/b80d2c7c5d4867232367cee793219dbbc00a3406))


### Bug Fixes

* better handling of pending jobs ([af2b9b5](https://github.com/S1M0N38/love2d.nvim/commit/af2b9b5d4f80d8c53c6c374d7384ef3c08d39ba8))
* **config:** search for love2d library based on runtimepath ([fe421a4](https://github.com/S1M0N38/love2d.nvim/commit/fe421a45846dcfa192133343f70fc662785eb392))
* **config:** select only one lib when multiple are provided ([7325877](https://github.com/S1M0N38/love2d.nvim/commit/732587735a1a89642f64bce632d6631b7dc0dc67))
* reuse the previous debug win if it exists ([1c8c589](https://github.com/S1M0N38/love2d.nvim/commit/1c8c58957a308da7d1567a4805ca6f03e25b849e))
* revert to blue/purple hearts in README ([bc19527](https://github.com/S1M0N38/love2d.nvim/commit/bc195279976e3797dcbc958498751c0f010ab817))
* use nvim api to set buf and win opts ([b83211d](https://github.com/S1M0N38/love2d.nvim/commit/b83211d8b905e5992c3c5e6c475f43d41f0ce6bf))
* warn notification when try to stop non-existing job ([06f1363](https://github.com/S1M0N38/love2d.nvim/commit/06f13631bc6fd7610522dba3dd4c7f476767313a))


### Code Refactoring

* change `path_to_love` to `path_to_love_bin` ([1ac7134](https://github.com/S1M0N38/love2d.nvim/commit/1ac7134e0566e2acb75b6cbd39c6e5b574a02420))


### Tests

* minimal init in Lua with lspconfig ([436f3ee](https://github.com/S1M0N38/love2d.nvim/commit/436f3ee3cda62696afd14a1877449f92a627d286))
