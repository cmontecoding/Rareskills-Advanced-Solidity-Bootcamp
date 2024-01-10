Conclusions from the fuzzer:

The fuzzer has limitations when there are a lot of different unrelated functions that can be called. It is also limited by deep solutions.
A workaround in this case is to make all functions internal and only expose neccesary functions to the problem, also create a hack function to show the direct steps.

The issue in the Dex is how getSwapPrice calculates the price. Not calculated evenly, based on the ratio of tokens to / tokens from so it is skewed to tokens exiting the pool.