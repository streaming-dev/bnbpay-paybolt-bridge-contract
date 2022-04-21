pragma solidity 0.6.4;

import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/GSN/Context.sol";

contract  Bridge is Context {
    using SafeERC20 for IERC20;
    mapping(uint256 => address) public tokenAddresses;

    address payable public owner;
    mapping(uint256 => uint256) public swapFees;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SwapStarted(uint256 fromChainId, uint256 indexed toChainId, address  indexed fromAddress, uint256 indexed amount);
    event SwapFilled(uint256 fromChainId, uint256 indexed toChainId, address indexed fromAddress, uint256 indexed amount);

    constructor() public {
        owner = _msgSender();
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
    
    function setToken(uint256 chainId, address tokenAddress) external onlyOwner {
    	tokenAddresses[chainId] = tokenAddress;
    }

    /**
    * @dev Leaves the contract without owner. It will not be possible to call
    * `onlyOwner` functions anymore. Can only be called by the current owner.
    *
    * NOTE: Renouncing ownership will leave the contract without an owner,
    * thereby removing any functionality that is only available to the owner.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Returns set minimum swap fee from BEP20 to ERC20
     */
    function setSwapFee(uint256 fee, uint256 chainId) onlyOwner external {
        swapFees[chainId] = fee;
    }


    /**
     * @dev fillSwap
     */
    function fillSwap(uint256 fromChainId, uint256 toChainId, address toAddress, uint256 amount) onlyOwner external returns (bool) {
        require(tokenAddresses[toChainId] != address(0x0), "no dest token exist");
        IERC20(tokenAddresses[toChainId]).transfer(toAddress, amount);
        emit SwapFilled(fromChainId, toChainId, toAddress, amount);
        return true;
    }
    /**
     * @dev swap
     */
    function swap(uint256 fromChainId, uint256 toChainId, uint256 amount) payable external notContract returns (bool) {
        require(tokenAddresses[fromChainId] != address(0x0), "no depature token exist");
        require(msg.value == swapFees[toChainId], "swap fee not equal");

        IERC20(tokenAddresses[fromChainId]).safeTransferFrom(msg.sender, address(this), amount);
        if (msg.value != 0) {
            owner.transfer(msg.value);
        }
        emit SwapStarted(fromChainId, toChainId, msg.sender, amount);
        return true;
    }
}