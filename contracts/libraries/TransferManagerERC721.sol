// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITransferManagerNFT} from "../interfaces/ITransferManagerNFT.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IArc721} from "../interfaces/IArc721.sol";

/**
 * @title TransferManagerERC721
 * @notice It allows the transfer of ERC721 tokens.
 */
contract TransferManagerERC721 is ITransferManagerNFT {
    address public immutable DEPO_EXCHANGE;

    /**
     * @notice Constructor
     * @param _depoExchange address of the Depo exchange
     */
    constructor(address _depoExchange) {
        DEPO_EXCHANGE = _depoExchange;
    }

    /**
     * @notice Transfer ERC721 token
     * @param collection address of the collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @dev For ERC721, amount is not used
     */
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) external override {
        require(msg.sender == DEPO_EXCHANGE, "Transfer: Only Depo Exchange");
        if (IERC165(collection).supportsInterface(type(IArc721).interfaceId)) {
            IArc721(collection).transferFromOrMint(from, to, tokenId);
        } else {
            IERC721(collection).safeTransferFrom(from, to, tokenId);
        }
    }
}
