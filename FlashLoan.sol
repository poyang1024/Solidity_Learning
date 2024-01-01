// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import {FlashLoanSimpleReceiverBase} from "https://github.com/aave/aave-v3-core/blob/master/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "https://github.com/aave/aave-v3-core/blob/master/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "https://github.com/aave/aave-v3-core/blob/master/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import { SafeMath } from "https://github.com/aave/aave-v3-core/contracts/dependencies/openzeppelin/contracts/SafeMath.sol";
// ----------------------INTERFACE------------------------------
// Uniswap
// Some helper function, it is totally fine if you can finish the lab without using these functions
interface IUniswapV2Router {

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns
     (uint amountToken, uint amountETH, uint liquidity);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (
      uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

}

interface IUniswapV2Pair {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external view returns (address);
}

// ----------------------IMPLEMENTATION------------------------------
contract FlashloanV3 is FlashLoanSimpleReceiverBase {
    // TODO: define constants used in the contract including ERC-20 tokens, Uniswap router, Aave address provider, etc.
    //  Aave V3 DAI address (Goerli testnet): 0xDF1742fE5b0bFc12331D8EAec6b478DfDbD31464
    //  Uniswap V2 router address (Goerli testnet): 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    //  addressProvider-Aave : 0xc4dCB5126a3AfEd129BC3668Ea19285A9f56D15D

    //address of the uniswap v2 router
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    //address of the token in goerli testnet
    address private constant A = 0x294f671d24eF75D1fF7A33eB1c26944d8BAE72eb;
    address private constant B = 0x279bD0b421393390ABC0A76eE042bC2Ed385D986;
    address private constant DAI = 0xDF1742fE5b0bFc12331D8EAec6b478DfDbD31464;

    // END TODO
    
    //防止數值溢出的安全問題
    using SafeMath for uint256;
    address payable owner;


    constructor(address _addressProvider)
        // TODO: (optional) initialize your contract
        //   *** Your code here ***
      FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider))
    {
      owner = payable(msg.sender);
    }
        // END TODO


    //
     //Allows users to access liquidity of one reserve or one transaction as long as the amount taken plus fee is returned.
     //@param _asset The address of the asset you want to borrow
     //@param _amount The borrow amount
    // Doc: https://docs.aave.com/developers/core-contracts/pool#flashloansimple

    function RequestFlashLoan(address _asset, uint256 _amount) public {
        address receiverAddress = address(this);
        address asset = _asset;
        uint256 amount = _amount;
        bytes memory params = "";
        uint16 referralCode = 0;

        // POOL comes from FlashLoanSimpleReceiverBase
        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referralCode
        );
    }

    /**
     * This function is called after your contract has received the flash loaned amount
     * @param asset The address of the asset you want to borrow
     * @param amount The borrow amount
     * @param premium The borrow fee
     * @param initiator The address initiates this function
     * @param params Arbitrary bytes-encoded params passed from flash loan
     * @return  true or false
     **/
    function executeOperation(address asset,uint256 amount,uint256 premium,address initiator,bytes calldata params) external override returns (bool)
    {
        // Step 1: Swap DAI to Token B
        uint256 amountB = _swapTokens(DAI, B, amount);

        // Step 2: Swap Token B to Token A
        uint256 amountA = _swapTokens(B, A, amountB);

        // Step 3: Swap Token A to DAI
        uint256 amountDAI = _swapTokens(A, DAI, amountA);

        // Step 4: Repay the loan
        uint256 totalDebtMoney = amount + premium; //借的錢加上借款手續費總金額
        IERC20(asset).approve(address(POOL),totalDebtMoney);

        return true;
    }

    function _swapTokens(
        address fromToken,
        address toToken,
        uint256 amount
    ) internal returns (uint256) {
        // Approve Uniswap Router to spend fromToken
        IERC20(fromToken).approve(UNISWAP_V2_ROUTER, 2**256-1);

        // Get the path for the swap
        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = toToken;

        // Perform the swap
        uint256 amounttoToken = IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            amount, // use the correct variable name here
            0,
            path,
            address(this),
            block.timestamp
        )[1];

        return amounttoToken;
    }

    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this))-500000000000000000);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    receive() external payable {}
}