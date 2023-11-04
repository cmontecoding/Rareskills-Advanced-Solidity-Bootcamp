# Problems with ERC777 and what ERC1363 solves

Both were created to solve the problem that smart contracts cant know if they received an ```ERC20```. Tries to inform the receiving smart contract that they received tokens.

## ERC777 Issues

```ERC777``` is an "upgrade" of ```ERC20``` by adding hooks (its backwards compatible). It has added QOL like rejecting unwanted tokens. 

Downfall is that ```ERC777``` is open to reentrancy attacks. ```ERC777``` makes the attack possible with tokens where it was believed that tokens were safe and eth was not. Reentrancy can be same function or cross function which is why we use the check effects pattern in general.

## ERC1363

```ERC1363``` does not override ```ERC20``` functions so it is backwards compatible. Adds "AndCall" to the end of ```ERC20``` functions.

Essentially adds a callback after a transfer or approval. Does it within a single transaction (rather than 2 which costs more gas). Notifies contract that is called. 

And behaves like normal ```ERC20``` so no reentrancy issues. Has known race condition issue but is from ```ERC20```.