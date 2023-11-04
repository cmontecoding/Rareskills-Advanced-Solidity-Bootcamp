# Why does the SafeERC20 program exist and when should it be used?

## Why It Exists

Standard ```ERC20``` transfer and transferFrom do not revert, instead they return a boolean of their success. So to revert if a function fails, you have to check the return value. Some non-standard tokens like ```USDT``` and ```BNB``` do not follow this standard so the return value will always return false. Which leads to unintended behavior. 

```SafeERC20``` is a library that wraps ```ERC20``` functions and reverts if the return value is false.

## When It Should Be Used

When a contract interacts with tokens that dont match ```IERC20``` return values. That contract should use ```SafeERC20``` to prevent weird ```ERC20``` implementations from breaking the protocol. 