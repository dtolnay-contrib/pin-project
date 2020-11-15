#!/bin/bash

# A script to run the simplified version of the checks done by CI.
#
# USAGE:
#     ./dev.sh [+toolchain] [subcommand] [options]
#
# Note: This script requires nightly Rust, rustfmt, clippy, and cargo-expand

set -euo pipefail
IFS=$'\n\t'

USAGE="USAGE:
    ./dev.sh [+toolchain] [subcommand] [options]

SUBCOMMANDS:
    test        Run tests (run all tests if no options are specified)
    fmt         Run rustfmt (nightly only)
    clippy      Run clippy (nightly only)
    doc         Build documentation (nightly only)
    help        Prints help information

Run all checks and tests if no subcommand is specified.
Specified [options] will be passed to 'cargo [subcommand]'."

if [[ "${1:-}" =~ --help|help ]]; then
  echo "${USAGE}"
  exit 0
fi

# Decide Rust toolchain. Nightly is used by default.
toolchain="+nightly"
if [[ "${1:-}" == "+"* ]]; then
  toolchain="${1}"
  shift
fi
# Make sure toolchain is installed.
if ! cargo "${toolchain}" -V &>/dev/null; then
  rustup toolchain install "${toolchain/+/}" --no-self-update --profile minimal
fi

# Parse subcommand.
if [[ ! "${1:-test}" =~ ^(test|fmt|clippy|doc)$ ]]; then
  echo "error: invalid argument: ${1}"
  exit 1
fi
if [[ "${toolchain}" != "+nightly"* ]]; then
  # Only tests are run in non-nightly toolchains.
  subcmd="${1:-test}"
  if [[ "${subcmd}" =~ fmt|clippy|doc ]]; then
    echo "error: subcommand '${subcmd}' is unavailable on non-nightly toolchains"
    exit 1
  fi
else
  subcmd="${1:-all}"
fi

# Run rustfmt.
if [[ "${subcmd}" =~ all|fmt ]]; then
  if ! rustup "${toolchain}" component add rustfmt &>/dev/null; then
    echo "error: component 'rustfmt' is unavailable for toolchain '${toolchain/+/}'"
    [[ -z "${1:-}" ]] || exit 1
  else
    echo "info: running 'cargo ${toolchain} fmt --all'"
    cargo "${toolchain}" fmt --all
  fi
fi

# Run clippy.
if [[ "${subcmd}" =~ all|clippy ]]; then
  if ! rustup "${toolchain}" component add clippy &>/dev/null; then
    echo "error: component 'clippy' is unavailable for toolchain '${toolchain/+/}'"
    [[ -z "${1:-}" ]] || exit 1
  else
    echo "info: running 'cargo ${toolchain} clippy --all --all-targets -Z unstable-options'"
    cargo "${toolchain}" clippy --all --all-features --all-targets -Z unstable-options
  fi
fi

# Run tests.
if [[ "${subcmd}" =~ all|test ]]; then
  if [[ -z "${1:-}" ]] || [[ -z "${2:-}" ]]; then
    if ! rustup "${toolchain}" component add rustfmt &>/dev/null ||
      ! cargo expand -V &>/dev/null; then
      echo "warning: dev.sh requires rustfmt and cargo-expand to run all tests"
    fi

    # Run all tests if no options are specified.
    echo "info: running 'cargo ${toolchain} test --all'"
    cargo "${toolchain}" test --all-features --all
  else
    if [[ "${2:-}" =~ -p|--package ]] && [[ "${3:-}" == "expandtest" ]]; then
      if ! rustup "${toolchain}" component add rustfmt &>/dev/null; then
          echo "error: component 'rustfmt' is unavailable for toolchain '${toolchain/+/}'"
          exit 1
      elif ! cargo expand -V &>/dev/null; then
          echo "error: expandtest requires cargo-expand"
          exit 1
      fi
    fi

    shift
    # Run tests with specified options.
    IFS=$' '
    echo "info: running 'cargo ${toolchain} test $*'"
    IFS=$'\n\t'
    cargo "${toolchain}" test --all-features "$@"
  fi
fi

# Build documentation.
if [[ "${subcmd}" =~ all|doc ]]; then
  if [[ -z "${1:-}" ]] || [[ -z "${2:-}" ]]; then
    echo "info: running 'cargo ${toolchain} doc --no-deps --all'"
    cargo "${toolchain}" doc --no-deps --all-features --all
  else
    shift
    IFS=$' '
    echo "info: running 'cargo ${toolchain} doc --no-deps $*'"
    IFS=$'\n\t'
    cargo "${toolchain}" doc --no-deps --all-features "$@"
  fi
fi
