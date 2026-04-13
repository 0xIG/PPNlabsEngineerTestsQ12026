# NOTES

## MiniVault smartcontract

* fixed bug with overminting shares
* fixed checks-effects pattern violation in `deposit` method
* all `require` statements changed to if-revert pattern with custom errors for better gas usage
* complete naming overhaul
* events and errors moved to interface `IMiniVault`
* added NatSpec comments with AI help

## computeUserPosition method
* implemented `computeUserPosition`
* `config` variable is ignored due to redundance with current logic

## GraphQL
* implemented query for `resolvers.ts`
* fixed interface for `schema.ts`
