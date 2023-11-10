# ERC721A

## How does ERC721A save gas?

1. It does not have redundant storage of each tokens metadata
2. The owners balance is updated once per batch mint instead of once per token in the batch
3. Updates the owners data once per batch not once per nft. meaning that if Alice buys 3 nfts then she will be recorded as the owner of nft 1. nft 2 and 3 will be empty. Later on we can lookup owner of 3 by looping back until we find the nearest owner (Alice). We have to change the ownerOf function to do that. The deferred owner slots may still get written into later on when NFTs are transferred but this still saves a lot of gas especially at mint time.

## Where does it add cost?

Adds costs to read functions and transferring to new owners.
