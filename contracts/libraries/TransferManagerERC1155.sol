// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ITransferManagerNFT} from "../interfaces/ITransferManagerNFT.sol";

interface IArc1155 is IERC1155 {
    function transferFromOrMint(
        address,
        address,
        uint256,
        uint256
    ) external;
}

/**
 * @title TransferManagerERC1155
 * @notice It allows the transfer of ERC1155 tokens.
 */
contract TransferManagerERC1155 is ITransferManagerNFT {
    address public immutable DEPO_EXCHANGE;

    /**
     * @notice Constructor
     * @param _depoExchange address of the Depo exchange
     */
    constructor(address _depoExchange) {
        DEPO_EXCHANGE = _depoExchange;
    }

    /**
     * @notice Transfer ERC1155 token(s)
     * @param collection address of the collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @param amount amount of tokens (1 and more for ERC1155)
     */
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external override {
        require(msg.sender == DEPO_EXCHANGE, "Transfer: Only Depo Exchange");
        IArc1155(collection).transferFromOrMint(from, to, tokenId, amount);
    }
}
