# Optimistic DNSSEC

[![Build Status](https://travis-ci.org/ensdomains/optimistic-dnssec.svg?branch=master)](https://travis-ci.org/ensdomains/dnssec-oracle) [![License](https://img.shields.io/badge/License-BSD--2--Clause-blue.svg)](LICENSE)

## Usage

1. User first calls `submit` function, opening a challenge period for the committed `record`.
2. If a record is not valid, any other user may call the `challenge` function for a chance to get the committing users stake.
3. If there was no challenge within the period, the `commit` function can be called, returning the stake to the submitter and storing the name in the registry.
