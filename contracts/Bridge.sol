pragma solidity 0.6.4;

import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/GSN/Context.sol";

contract  Bridge is Context {
    using SafeERC20 for IERC20;

    address public tokenAddress;
    uint256 public minAmount;
    address payable public owner;
    mapping(uint256 => uint256) public swapFees;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SwapStarted(uint256 fromChainId, uint256 indexed toChainId, address  indexed fromAddress, uint256 indexed amount);
    event SwapFilled(uint256 fromChainId, uint256 indexed toChainId, address indexed fromAddress, uint256 indexed amount);
    event TokenDeposited(uint256 indexed amount);
    event TokenWithdrawn(address indexed toAddress, uint256 indexed amount);

    constructor(address _tokenAddress, uint256 _minAmount, uint256 _toChainId1, uint256 _toSwapFee1, uint256 _toChainId2, uint256 _toSwapFee2) public {
        owner = _msgSender();
        tokenAddress = _tokenAddress;
        minAmount = _minAmount;
        swapFees[_toChainId1] = _toSwapFee1;
        swapFees[_toChainId2] = _toSwapFee2;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier notContract() {
        require(!isContract(msg.sender), "contract is not allowed to swap");
        require(msg.sender == tx.origin, "no proxy contract is allowed");
       _;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
    function setToken(address _tokenAddress) external onlyOwner {
    	tokenAddress = _tokenAddress;
    }

    function setMinAmount(uint256 _minAmount) external onlyOwner {
        require(_minAmount > 0, "need more amount than zero");
    	minAmount = _minAmount;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Returns set minimum swap fee from BEP20 to ERC20
     */
    function setSwapFee(uint256 _chainId, uint256 _fee) external onlyOwner {
        require(_fee > 0, "need more amount than zero");
        swapFees[_chainId] = _fee;
    }

    /**
     * @dev fillSwap
     */
    function fillSwap(uint256 fromChainId, uint256 toChainId, address toAddress, uint256 amount) onlyOwner external returns (bool) {
        require(tokenAddress != address(0x0), "no dest token exist");
        IERC20(tokenAddress).transfer(toAddress, amount);
        emit SwapFilled(fromChainId, toChainId, toAddress, amount);
        return true;
    }
    /**
     * @dev swap
     */
    function swap(uint256 fromChainId, uint256 toChainId, uint256 amount) payable external notContract returns (bool) {
        require(tokenAddress != address(0x0), "no depature token exist");
        require(msg.value == swapFees[toChainId], "swap fee not equal");
        require(amount >= minAmount, "need more amount than minimum amount");

        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        if (msg.value != 0) {
            owner.transfer(msg.value);
        }
        emit SwapStarted(fromChainId, toChainId, msg.sender, amount);
        return true;
    }

    /**
     * @dev Deposite tokens for brige swap
     */
    function depositToken(uint256 _amount) external onlyOwner {
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
        emit TokenDeposited(_amount);
    }

    /**
     * @dev Withdraw the deposited tokens in brige.
     */
    function withdrawToken() external onlyOwner {
        uint256 totalAmount = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(msg.sender, totalAmount);
        emit TokenWithdrawn(msg.sender, totalAmount);
    }
}