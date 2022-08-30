// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./libraries/OperatorRole.sol";
import {IArc721} from "./interfaces/IArc721.sol";

/**
 * @title Arc721
 * Arc721 - ERC721 contract that has minting functionality.
 */
contract Arc721 is OperatorRole, ERC721, ERC721Enumerable {
    string public uri;

    /// @notice Contract constructor
    constructor(string memory uri_) ERC721("Arc721", "ARC721") {
        uri = uri_;
    }

    /// @notice Set the base URI
    function setBaseURI(string memory uri_) external onlyOperator {
        uri = uri_;
    }

    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    function _generateRandomId(
        address user,
        uint256 timestamp,
        uint256 nonce
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(user, timestamp, nonce)));
    }

    /**
     * @dev mints new NFT and returns minted item's id
     *
     * @return tokenId id of new item
     */
    function mint() external returns (uint256 tokenId) {
        uint256 nonce;
        tokenId = _generateRandomId(msg.sender, block.timestamp, nonce);
        while (_exists(tokenId)) {
            unchecked {
                nonce++;
            }
            tokenId = _generateRandomId(msg.sender, block.timestamp, nonce);
        }

        _mint(msg.sender, tokenId);
    }

    /**
     * @dev mints new NFT and returns minted item's id
     *
     * @param amount number of tokens to mint
     * @return ids ids of new items
     */
    function batchMint(uint256 amount) external returns (uint256[] memory ids) {
        ids = new uint256[](amount);
        uint256 i;
        uint256 nonce;
        for (; i < amount; i++) {
            uint256 tokenId = _generateRandomId(msg.sender, block.timestamp, nonce);
            while (_exists(tokenId)) {
                unchecked {
                    nonce++;
                }
                tokenId = _generateRandomId(msg.sender, block.timestamp, nonce);
            }
            _mint(msg.sender, tokenId);
            ids[i] = tokenId;
            nonce++;
        }
    }

    /**
     * @dev transfer the token if the tokenId exists, otherwise mint the token
     *
     * Add the TransferManagerERC721 address as an operator to allow the lazymint
     *
     * @param from address that is sending a token
     * @param to address that is receiving a token
     * @param tokenId token id that is being sent or minted
     */
    function transferFromOrMint(
        address from,
        address to,
        uint256 tokenId
    ) external onlyOperator {
        if (_exists(tokenId)) {
            safeTransferFrom(from, to, tokenId, "");
        } else {
            _mint(to, tokenId);
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return type(IArc721).interfaceId == interfaceId || super.supportsInterface(interfaceId);
    }
}
