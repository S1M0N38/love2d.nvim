# Changelog

## [3.0.0](https://github.com/S1M0N38/love2d.nvim/compare/v2.1.0...v3.0.0) (2026-05-11)


### ⚠ BREAKING CHANGES

* :LoveRun and :LoveStop commands removed. Use :Love run and :Love stop instead.

### Features

* **autocmd:** add enter/leave project handlers ([962e3ac](https://github.com/S1M0N38/love2d.nvim/commit/962e3ac97794548f6c0cba4a6cfd5126c0a10148))
* **compiler:** add compiler/love.lua, extract utils.lua ([c091422](https://github.com/S1M0N38/love2d.nvim/commit/c091422ce7d748384fcf063dda74d73e5988ef31))
* **config:** add lsp option to disable automatic lua_ls setup ([6767874](https://github.com/S1M0N38/love2d.nvim/commit/6767874ee9444f294feb8b4491d64342be387cc9))
* **events:** add DirChanged/BufEnter project detection events ([2d9e71f](https://github.com/S1M0N38/love2d.nvim/commit/2d9e71f016c578eab956b1d7afd76d17575b2070))
* **health:** add :checkhealth love2d support ([fa40801](https://github.com/S1M0N38/love2d.nvim/commit/fa4080172a80855b31b8006ee009062528b9f1c3))
* **init:** add did_setup guard to prevent double setup ([c4842ae](https://github.com/S1M0N38/love2d.nvim/commit/c4842ae540cd44c9ee8a6e2d8fc4d637be110e76))
* **job:** add process lifecycle module with run/watch/stop/info ([ed0163f](https://github.com/S1M0N38/love2d.nvim/commit/ed0163fbca5cbe8dcd9067d862802473e5ccca44))
* **output:** add floating output panel with diagnostics ([ea708a9](https://github.com/S1M0N38/love2d.nvim/commit/ea708a9abafd28d356d9efba11d074e86276dff5))
* **types:** add separate LuaLS type definition file ([377c845](https://github.com/S1M0N38/love2d.nvim/commit/377c84576a43e55fa869de8c74c26d536c2e988d))
* unified :Love command, lspconfig-free LSP, and auto project detection ([1482651](https://github.com/S1M0N38/love2d.nvim/commit/1482651f41d7d70d0b9054bac4930feb1e61e9c0))


### Bug Fixes

* **ci:** add vim as known global in .luarc.json ([44a83bb](https://github.com/S1M0N38/love2d.nvim/commit/44a83bb948b3461dfba1fe3958f0b584dec59aa1))
* **ci:** pass VIM env var to typecheck action ([4e8df77](https://github.com/S1M0N38/love2d.nvim/commit/4e8df77c747eb7e476a15246006904c9bbd7025d))
* **ci:** use Neovim runtime types instead of diagnostics.globals hack ([88702a0](https://github.com/S1M0N38/love2d.nvim/commit/88702a0336974299cc94cd6610ba7ae0a4144b09))
* **compiler:** remove invalid backslash-space escape in errorformat ([a10a59d](https://github.com/S1M0N38/love2d.nvim/commit/a10a59d2706ecb8150b421a8ea9359b30ee97320))
* **compiler:** use buffer-local guard to allow re-running :compiler love ([71ad1ec](https://github.com/S1M0N38/love2d.nvim/commit/71ad1ec10d8303ff22c2a05639a630f4a4919ca5))
* **compiler:** use long string syntax for errorformat ([97a6b58](https://github.com/S1M0N38/love2d.nvim/commit/97a6b586571a1f38ab99c4f790f21e43fb994383))
* **config:** set compiler for already-opened lua buffers ([ec998c6](https://github.com/S1M0N38/love2d.nvim/commit/ec998c60f3249e105eb5f5109404f758d273422b))
* **job:** pass command as list to jobstart ([cd11091](https://github.com/S1M0N38/love2d.nvim/commit/cd11091cc7a102ebee01d4de5c0cb19af973faf2))
* **lsp:** add cmd to lua_ls config so the server can start ([f647d44](https://github.com/S1M0N38/love2d.nvim/commit/f647d440ee52c58b47c36f131398e336c8e48eef))
* **lsp:** register lsp autocmds before events.setup ([d0d2b55](https://github.com/S1M0N38/love2d.nvim/commit/d0d2b55ee9f91ff5d6999cc83f7519dcda7a2581))
* **plugin:** show usage when :Love is called without args ([e08a035](https://github.com/S1M0N38/love2d.nvim/commit/e08a035dec4370d7ee0cd0dfe909cb7bcb0f88a1))
* **plugin:** use plain prefix match for :Love completion ([7163390](https://github.com/S1M0N38/love2d.nvim/commit/7163390ae105a38a88990bb40352b5bc16097a5e))
* **skills:** correct test framework reference in nvim-plugin skill ([8d5fd9a](https://github.com/S1M0N38/love2d.nvim/commit/8d5fd9a35dd0bea8c0cea24283b4a7e9edb39d31))
* **tests:** restore cwd correctly in events_spec, update job_spec ([ffc6097](https://github.com/S1M0N38/love2d.nvim/commit/ffc609727326e9384bba08c2b2977533da25ab30))

## [2.1.0](https://github.com/S1M0N38/love2d.nvim/compare/v2.0.0...v2.1.0) (2025-08-04)


### Features

* add makeprg and errorformat autocommand setup ([a93beb0](https://github.com/S1M0N38/love2d.nvim/commit/a93beb0bacae571f98b2252fb7dd4091eaacd835))

## [2.0.0](https://github.com/S1M0N38/love2d.nvim/compare/v1.1.0...v2.0.0) (2025-07-22)


### ⚠ BREAKING CHANGES

* Remove path_to_love_library and path_to_luasocket_library configuration options. The plugin now uses bundled library paths automatically for LSP setup.

### Features

* add repro.lua for reproducing issues ([dbbdd6d](https://github.com/S1M0N38/love2d.nvim/commit/dbbdd6d152127b2e7d06abb5b99c8b2c04e8b736))
* adding optional improvements ([17331bc](https://github.com/S1M0N38/love2d.nvim/commit/17331bc541c5e1572d5634eb17117438bd53ab73))


### Bug Fixes

* **ci:** update command to install luacheck ([5f8957a](https://github.com/S1M0N38/love2d.nvim/commit/5f8957ace8b92dbfba4019e70b7d5fc4d4905ff7))
* switching strategy ([7bc69b3](https://github.com/S1M0N38/love2d.nvim/commit/7bc69b3263f93e1f57be926f348b1d1d15d82bb7))
* trying to make it work with lspconfig ([5c5d629](https://github.com/S1M0N38/love2d.nvim/commit/5c5d629386689024017ce1cc278ebf0978b7f0f0))
* type for debug_window_opts ([e08d192](https://github.com/S1M0N38/love2d.nvim/commit/e08d192705944ff6f29e453036417a41cf3de17c))


### Code Refactoring

* remove manual library path configuration options ([1744488](https://github.com/S1M0N38/love2d.nvim/commit/1744488b0d2b76497340bc9904ef9ae5079a86f8))

## [1.1.0](https://github.com/S1M0N38/love2d.nvim/compare/v1.0.1...v1.1.0) (2025-06-28)


### Features

* **luasocket:** add luasocket annotations as git submodule ([875cda6](https://github.com/S1M0N38/love2d.nvim/commit/875cda62a21008ff5e2e2d0460b6f25a0c9b7e11))
* **luasocket:** update config to accept luasocket lib path ([ab0fe6d](https://github.com/S1M0N38/love2d.nvim/commit/ab0fe6d8730a5dd0113e03ba524db53c2bc4cddd))

## [1.0.1](https://github.com/S1M0N38/love2d.nvim/compare/v1.0.0...v1.0.1) (2025-04-16)


### Bug Fixes

* use VeryLazy event instead cmd ([#8](https://github.com/S1M0N38/love2d.nvim/issues/8)) ([c9ad2b6](https://github.com/S1M0N38/love2d.nvim/commit/c9ad2b61e5c433b45679b2f2b0ed4682fe2c6bd7))

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
