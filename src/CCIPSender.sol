// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";

contract CCIPSender {
    using SafeERC20 for IERC20;

    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error NothingToWithdraw();
    error FailedToWithdrawEth(address owner, address target, uint256 value);

    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        string message,
        address feeToken,
        uint256 fees
    );

    IRouterClient public immutable router;
    address public immutable owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(address _router) {
        router = IRouterClient(_router);
        owner = msg.sender;
    }

    /// @notice Sends a text message to a receiver on a different chain
    /// @param destinationChainSelector The chain selector for the destination chain
    /// @param receiver The address of the receiver contract on the destination chain
    /// @param message The text message to send
    /// @param feeTokenAddress The address of the token to pay fees (address(0) for native token)
    /// @return messageId The ID of the sent message
    function sendMessage(
        uint64 destinationChainSelector,
        address receiver,
        string calldata message,
        address feeTokenAddress
    ) external payable returns (bytes32 messageId) {
        // Create an EVM2AnyMessage struct
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(message),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200_000})
            ),
            feeToken: feeTokenAddress
        });

        // Get the fee required to send the message
        uint256 fees = router.getFee(destinationChainSelector, evm2AnyMessage);

        if (feeTokenAddress == address(0)) {
            // Pay in native token (HBAR or ETH)
            if (msg.value < fees) {
                revert NotEnoughBalance(msg.value, fees);
            }

            messageId = router.ccipSend{value: fees}(
                destinationChainSelector,
                evm2AnyMessage
            );
        } else {
            // Pay in ERC20 token (LINK or WHBAR)
            if (IERC20(feeTokenAddress).balanceOf(msg.sender) < fees) {
                revert NotEnoughBalance(
                    IERC20(feeTokenAddress).balanceOf(msg.sender),
                    fees
                );
            }

            // Transfer tokens from sender to this contract
            IERC20(feeTokenAddress).safeTransferFrom(msg.sender, address(this), fees);

            // Approve the router to spend tokens
            IERC20(feeTokenAddress).approve(address(router), fees);

            messageId = router.ccipSend(destinationChainSelector, evm2AnyMessage);
        }

        emit MessageSent(
            messageId,
            destinationChainSelector,
            receiver,
            message,
            feeTokenAddress,
            fees
        );

        return messageId;
    }

    /// @notice Allows the owner to withdraw the entire balance of native tokens
    function withdraw(address _beneficiary) public onlyOwner {
        uint256 amount = address(this).balance;
        if (amount == 0) revert NothingToWithdraw();
        (bool sent, ) = _beneficiary.call{value: amount}("");
        if (!sent) revert FailedToWithdrawEth(msg.sender, _beneficiary, amount);
    }

    /// @notice Allows the owner to withdraw tokens
    function withdrawToken(address _beneficiary, address _token) public onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        if (amount == 0) revert NothingToWithdraw();
        IERC20(_token).safeTransfer(_beneficiary, amount);
    }

    receive() external payable {}
}
