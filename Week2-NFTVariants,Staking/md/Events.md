# Revisit the solidity events tutorial

## How can OpenSea quickly determine which NFTs an address owns if most NFTs don’t use ERC721 enumerable?

They listen to all the transfer/mint events on the blockchain to see who owns what.

## Explain how you would accomplish this if you were creating an NFT marketplace

I would listen to every block and track all the nfts and owners in an off chain database. That way there is easy lookup on the front end.