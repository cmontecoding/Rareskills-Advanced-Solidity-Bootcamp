pragma solidity 0.8.21;

import {Test} from "forge-std/test.sol";
import {UniswapV2Pair, ERC20} from "../src/UniswapV2Pair.sol";
import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";

contract UniswapV2PairTest is Test {
    UniswapV2Factory factory;
    UniswapV2Pair pair;
    dummyToken token0;
    dummyToken token1;

    function setUp() public {
        token0 = new dummyToken("token0", "T0");
        token1 = new dummyToken("token1", "T1");
        factory = new UniswapV2Factory(address(this));
        factory.createPair(address(token0), address(token1));
        pair = UniswapV2Pair(factory.getPair(address(token0), address(token1)));

        token0.mint(address(this), 10e18);
        token1.mint(address(this), 10e18);
    }

    function testMint() public {
        token0.transfer(address(pair), 1e18);
        token1.transfer(address(pair), 1e18);

        pair.mint(address(this));
        /// @dev 1e18 - 10e3 (minimum liquidity which is burned) = 999999999999999000
        assertEq(pair.balanceOf(address(this)), 999999999999999000);
        assertEq(pair.balanceOf(address(0)), pair.MINIMUM_LIQUIDITY());
        assertEq(token0.balanceOf(address(pair)), 1e18);
        assertEq(token1.balanceOf(address(pair)), 1e18);
        assertEq(pair.totalSupply(), pair.MINIMUM_LIQUIDITY() + 999999999999999000);
        /// @dev same as 1e18 (sanity check)
        assertEq(pair.totalSupply(), 1e18);
    }

    function testBurn() public {
        token0.transfer(address(pair), 1e18);
        token1.transfer(address(pair), 1e18);
        pair.mint(address(this));

        pair.transfer(address(pair), 999999999999999000);
        pair.burn(address(this));
        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(pair.balanceOf(address(pair)), 0);
        assertEq(pair.totalSupply(), pair.MINIMUM_LIQUIDITY());
        assertEq(token0.balanceOf(address(pair)), 1000);
        assertEq(token1.balanceOf(address(pair)), 1000);
        assertEq(token0.balanceOf(address(this)), 10e18 - 1000);
        assertEq(token1.balanceOf(address(this)), 10e18 - 1000);

        /// @dev sanity check that tokens werent burned
        assertEq(token0.totalSupply(), 10e18);
        assertEq(token1.totalSupply(), 10e18);
    }

    function testSwap() public {
        token0.transfer(address(pair), 1e18);
        token1.transfer(address(pair), 1e18);
        pair.mint(address(this));

        token0.transfer(address(pair), 1000);
        pair.swap(900, 0, address(this), "");
        assertEq(token0.balanceOf(address(pair)), 1e18 + 1000);
        assertEq(token1.balanceOf(address(pair)), 1e18 - 900);
        assertEq(token0.balanceOf(address(this)), 10e18 - 1e18 - 1000);
        assertEq(token1.balanceOf(address(this)), 10e18 - 1e18 + 900);
    }

    function testMaxFlashLoan() public {
        token0.transfer(address(pair), 1e18);
        token1.transfer(address(pair), 2e18);
        pair.sync();
        assertEq(token0.balanceOf(address(pair)), 1e18);
        assertEq(pair.maxFlashLoan(address(token0)), 1e18);
        assertEq(token1.balanceOf(address(pair)), 2e18);
        assertEq(pair.maxFlashLoan(address(token1)), 2e18);
    }


    function testSkim() public {
        token0.transfer(address(pair), 1e18);
        assertEq(token0.balanceOf(address(pair)), 1e18);
        pair.skim(address(this));
        assertEq(token0.balanceOf(address(pair)), 0);
        assertEq(token0.balanceOf(address(this)), 10e18);
    }

}

contract dummyToken is ERC20 {

    constructor(string memory name_, string memory symbol_) {
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function name() public view override returns (string memory) {
        return "name";
    }

    function symbol() public view override returns (string memory) {
        return "symbole";
    }

}