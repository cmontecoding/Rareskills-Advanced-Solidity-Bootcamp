pragma solidity 0.8.21;

import "./interfaces/IUniswapV2Pair.sol";
import "./libraries/UQ112x112.sol";
import "./interfaces/IUniswapV2Factory.sol";
import {ERC20} from "solady/src/tokens/ERC20.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";
import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";
import {IERC3156FlashLender, IERC3156FlashBorrower} from "@openzeppelin/interfaces/IERC3156FlashLender.sol";

contract UniswapV2Pair is
    IUniswapV2Pair,
    ERC20,
    ReentrancyGuard,
    IERC3156FlashLender
{
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    function name() public view virtual override returns (string memory) {
        return "Uniswap V2";
    }

    function symbol() public view virtual override returns (string memory) {
        return "UNI-V2";
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "UniswapV2: TRANSFER_FAILED"
        );
    }

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "UniswapV2: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint balance0,
        uint balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(
            balance0 <= type(uint112).max && balance1 <= type(uint112).max,
            "UniswapV2: OVERFLOW"
        );
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        unchecked {
            uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
            if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
                // * never overflows, and + overflow is desired
                price0CumulativeLast +=
                    uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) *
                    timeElapsed;
                price1CumulativeLast +=
                    uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) *
                    timeElapsed;
            }
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(
        uint112 _reserve0,
        uint112 _reserve1
    ) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = FixedPointMathLib.sqrt(
                    uint(_reserve0) * (_reserve1)
                );
                uint rootKLast = FixedPointMathLib.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply() * (rootK - (rootKLast));
                    uint denominator = rootK * (5) + (rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function _addLiquidity(
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        (uint reserveA, uint reserveB, ) = getReserves();
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "UniswapV2Router: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "UniswapV2Router: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) internal pure returns (uint amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = (amountA * reserveB) / reserveA;
    }

    /// @dev refactored to avoid stack too deep
    function mintWithChecks(
        address to,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) external nonReentrant returns (uint liquidity) {
        (uint amountA, uint amountB) = _addLiquidity(
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        ERC20(token0).transferFrom(msg.sender, address(this), amountA);
        ERC20(token1).transferFrom(msg.sender, address(this), amountB);
        liquidity = mint(to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) internal returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - (_reserve0);
        uint amount1 = balance1 - (_reserve1);

        /// @dev Add check to make sure funds were sent to the contract
        /// for users who are not using the Uniswap router
        require(
            amount0 > 0 && amount1 > 0,
            "UniswapV2: INSUFFICIENT_INPUT_AMOUNT"
        );

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity =
                FixedPointMathLib.sqrt(amount0 * (amount1)) -
                (MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = FixedPointMathLib.min(
                (amount0 * (_totalSupply)) / _reserve0,
                (amount1 * (_totalSupply)) / _reserve1
            );
        }
        require(liquidity > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * (reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    /// @dev refactored to avoid stack too deep
    function burnWithChecks(
        address to,
        uint liquidity,
        uint amountAMin,
        uint amountBMin
    ) external nonReentrant returns (uint amount0, uint amount1) {
        /// @dev send liquidity to pair
        ERC20(address(this)).transferFrom(msg.sender, address(this), liquidity);
        (amount0, amount1) = burn(to);
        require(amount0 >= amountAMin, "UniswapV2: INSUFFICIENT_A_AMOUNT");
        require(amount1 >= amountBMin, "UniswapV2: INSUFFICIENT_B_AMOUNT");
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) internal returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint balance0 = ERC20(_token0).balanceOf(address(this));
        uint balance1 = ERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf(address(this));

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = (liquidity * (balance0)) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = (liquidity * (balance1)) / _totalSupply; // using balances ensures pro-rata distribution
        require(
            amount0 > 0 && amount1 > 0,
            "UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED"
        );
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = ERC20(_token0).balanceOf(address(this));
        balance1 = ERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * (reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swapExactTokens0ForTokens1(
        uint amountIn,
        uint amountOutMin,
        address to
    ) external nonReentrant {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        (uint reserveIn, uint reserveOut, ) = getReserves();
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        uint amountOut = numerator / denominator;
        require(
            amountOut >= amountOutMin,
            "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        ERC20(token0).transferFrom(msg.sender, address(this), amountIn);
        swap(0, amountOut, to);
    }

    function swapExactTokens1ForTokens0(
        uint amountIn,
        uint amountOutMin,
        address to
    ) external nonReentrant {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        (uint reserveOut, uint reserveIn, ) = getReserves();
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        uint amountOut = numerator / denominator;
        require(
            amountOut >= amountOutMin,
            "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        ERC20(token1).transferFrom(msg.sender, address(this), amountIn);
        swap(amountOut, 0, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to) internal {
        require(
            amount0Out > 0 || amount1Out > 0,
            "UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "UniswapV2: INSUFFICIENT_LIQUIDITY"
        );

        uint balance0;
        uint balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "UniswapV2: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            balance0 = ERC20(_token0).balanceOf(address(this));
            balance1 = ERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve1 - amount1Out)
            : 0;
        require(
            amount0In > 0 || amount1In > 0,
            "UniswapV2: INSUFFICIENT_INPUT_AMOUNT"
        );
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint balance0Adjusted = balance0 * (1000) - (amount0In * (3));
            uint balance1Adjusted = balance1 * (1000) - (amount1In * (3));
            require(
                balance0Adjusted * (balance1Adjusted) >=
                    uint(_reserve0) * (_reserve1) * (1000 ** 2),
                "UniswapV2: K"
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function maxFlashLoan(
        address token
    ) external view override returns (uint256) {
        if (token == token0) {
            return reserve0;
        } else if (token == token1) {
            return reserve1;
        } else {
            return 0;
        }
    }

    function flashFee(
        address token,
        uint256 amount
    ) public view override returns (uint256) {
        require(token == token0 || token == token1, "UniswapV2: INVALID_TOKEN");
        return (amount * (3)) / (1000);
    }

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        uint256 fee = flashFee(token, amount);
        _safeTransfer(token, address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) ==
                keccak256("ERC3156FlashBorrower.onFlashLoan"),
            "IERC3156: Callback failed"
        );
        require(
            ERC20(token).transferFrom(
                address(receiver),
                address(this),
                amount + (fee)
            ),
            "UniswapV2: TRANSFER_FROM_FAILED"
        );
        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this));
        _update(balance0, balance1, reserve0, reserve1);
        return true;
    }

    // force balances to match reserves
    function skim(address to) external nonReentrant {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(
            _token0,
            to,
            ERC20(_token0).balanceOf(address(this)) - (reserve0)
        );
        _safeTransfer(
            _token1,
            to,
            ERC20(_token1).balanceOf(address(this)) - (reserve1)
        );
    }

    // force reserves to match balances
    function sync() external nonReentrant {
        _update(
            ERC20(token0).balanceOf(address(this)),
            ERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }
}
