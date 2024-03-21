Question 1: The OZ upgrade tool for hardhat defends against 6 kinds of mistakes. What are they and why do they matter?

Not sure. Never used hardhat for upgrades.

Question 2: What is a beacon proxy used for?

For when we want multiple proxy contracts to have the same implementation and to be able to upgrade them all at once.

Question 3: Why does the openzeppelin upgradeable tool insert something like uint256[50] private __gap; inside the contracts? To see it, create an upgradeable smart contract that has a parent contract and look in the parent.

This is for when you have larger smart contract architectures and you upgrade and add new storage slots. In a situation with just 1 contract you can append storage. But in a situation with multiple contracts you might not be able to append storage properly like if it is on a parent contract: this would shift the storage slots of the child contracts. The gap allows parent contracts to add storage slots without shifting the storage slots of the child contracts. When you add a storage slot you remove a value from the gap. This is a way to future proof the contracts. 

Question 4: What is the difference between initializing the proxy and initializing the implementation? Do you need to do both? When do they need to be done?

Initializing the proxy is the constructor for the proxy, so you do this when you deploy the proxy. You need to initialize the implementation upon deployment within the constructor that way someone else cannot reinitialize the implementation. You need to do both.

Question 5: What is the use for the reinitializer? Provide a minimal example of proper use in Solidity

Used for intializing again in future upgrades. Useful for when you upgrade and add new storage slots but you want to now initialize the new storage slots. 