# 20. Denial

The success of the call is not checked so it can silently fail and take up all the gas in the process.
An infinite while loop in the DenialAttacker contract uses up all the gas in the call. This prevents
the owner from being able to withdraw funds.
