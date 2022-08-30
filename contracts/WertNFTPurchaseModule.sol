// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./libraries/OrderTypes.sol";
import "./interfaces/IDepoExchange.sol";

contract WertNFTPurchaseModule is IERC721Receiver {
    IDepoExchange public exchange;

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    event TokenPurchased(address user, address token, uint256 amountIn, uint256 amountOut);

    constructor(address _exchange) {
        require(_exchange != address(0), "missing exchange address");
        exchange = IDepoExchange(_exchange);
    }

    /**
     * @notice purchase ERC20 token
     * @param _takerBid  taker bid order
     * @param _makerAsk  maker ask order
     * @return bool
     */
    function purchaseNFTWithETH(OrderTypes.TakerOrder memory _takerBid, OrderTypes.MakerOrder calldata _makerAsk)
        external
        payable
        returns (bool)
    {
        address to = _takerBid.taker;
        _takerBid.taker = address(this);

        exchange.matchAskWithTakerBidUsingETHAndWETH{value: msg.value}(_takerBid, _makerAsk);

        address collection = _makerAsk.collection;
        if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(collection).safeTransferFrom(address(this), to, _makerAsk.tokenId);
        } else if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)) {
            IERC1155(collection).safeTransferFrom(address(this), to, _makerAsk.tokenId, _makerAsk.amount, bytes(""));
        }

        return true;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
