SHELL := /usr/bin/env bash

.PHONY: init
init:
	./scripts/init.sh

.PHONY: check
check:
	export SKIP_WASM_BUILD=1
	cargo check --all
	cargo check --all --tests
	make check-no-std
	make check-benchmarks

.PHONY: check-benchmarks
check-benchmarks:
	export SKIP_WASM_BUILD=1
	cargo check --features=runtime-benchmarks; popd

.PHONY: check-no-std
check-no-std:
	pushd pallets/sp-mvm && cargo check -p=sp-mvm --target=wasm32-unknown-unknown --no-default-features; popd

.PHONY: clippy
clippy:
	cargo clippy -p=sp-mvm -p=sp-mvm-rpc -p=sp-mvm-rpc-runtime
	pushd pallets/sp-mvm && cargo clippy -p=sp-mvm --target=wasm32-unknown-unknown --no-default-features

.PHONY: bench
bench: assets
	# This is just an example about how to run benchmarks for the pallet
	mkdir -p ./target/sp-bench
	cargo run \
		--release \
		--bin pontem \
		--features=runtime-benchmarks -- \
		benchmark \
		--dev \
		-lsp_mvm=trace \
		--pallet=sp_mvm \
		--extrinsic='*' \
		--execution=wasm \
		--wasm-execution=compiled \
		--steps=20 --repeat=10 \
		--output=target/sp-bench

.PHONY: test
test:
	make assets
	export SKIP_WASM_BUILD=1
	cargo test --all --no-fail-fast -- --nocapture --test-threads=1

.PHONY: run
run:
	export WASM_BUILD_TOOLCHAIN=`cat rust-toolchain`
	cargo run --release -- --dev --tmp -lsp_mvm=trace

.PHONY: build
build:
	export WASM_BUILD_TOOLCHAIN=`cat rust-toolchain`
	cargo build --release

.PHONY: assets
assets: pallets/sp-mvm/tests/assets/stdlib pallets/sp-mvm/tests/benchmark_assets/stdlib

pallets/sp-mvm/tests/assets/stdlib:
	pushd pallets/sp-mvm/tests/assets && ./build_assets.sh

pallets/sp-mvm/tests/benchmark_assets/stdlib:
	pushd pallets/sp-mvm/tests/benchmark_assets && ./build_assets.sh

.PHONY: coverage
coverage:
	make assets
	export SKIP_WASM_BUILD=1
	export CARGO_INCREMENTAL=0
	export RUSTFLAGS="-Zprofile -Ccodegen-units=1 -Cinline-threshold=0 -Clink-dead-code -Coverflow-checks=off -Zno-landing-pads"
	# export RUSTFLAGS="-Zprofile -Ccodegen-units=1 -Cinline-threshold=0 -Clink-dead-code -Coverflow-checks=off"
	export RUSTDOCFLAGS="-Cpanic=abort"
	# cargo test -p=sp-mvm --no-fail-fast -- --test-threads=1
	cargo test --no-fail-fast -- --test-threads=1
	grcov . \
		-s . \
		--binary-path ./target/debug/ \
		--guess-directory-when-missing \
		--llvm \
		--branch \
		--ignore-not-existing \
		--filter covered \
		-o ./target/debug/coverage/
	# to produce html report add:
	# -t html
