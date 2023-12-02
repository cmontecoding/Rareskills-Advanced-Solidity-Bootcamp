# How To Use The UniswapV2 TWAP Oracle

## Why does the ```price0CumulativeLast``` and ```price1CumulativeLast``` never decrement?

They never decrement because it is a cumulative so it should always increase. It represents the sum of the Uniswap price for every second in the entire history of the contract. Also, it never overflows and an overflow would be desired.

## How do you write a contract that uses the oracle?

You look at the price0/price1cumulativelast variable at the desired start and end of your interval, then you divide the difference by the length of the interval to get the weighted average price (over that interval), otherwise known as the TWAP.

## Why are ```price0CumulativeLast``` and ```price1CumulativeLast``` stored separately? Why not just calculate ```price1CumulativeLast = 1/price0CumulativeLast```?

They are stored separately because you lose accuracy when trying to convert from one to the other.