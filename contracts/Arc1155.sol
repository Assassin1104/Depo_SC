// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libraries/OperatorRole.sol";

/**
 * @title Arc1155
 * Arc1155 - ERC1155 contract that has mint functionality,
 * and supports useful standards from OpenZeppelin
 */
contract Arc1155 is OperatorRole, ERC1155, ERC1155Supply {
    using Strings for uint256;

    // Contract name
    string public name = "Arc1155";
    // Contract symbol
    string public symbol = "ARC1155";

    constructor(string memory uri_) ERC1155(uri_) {}

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "ERC1155Metadata: URI query for nonexistent token");

        string memory baseURI = super.uri(_id);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _id.toString())) : "";
    }

    /**
     * @dev transfer the token if the tokenId exists, otherwise mint the token
     *
     * Add the TransferManagerERC1155 address as an operator to allow the lazymint
     *
     * @param from address that is sending a token
     * @param to address that is receiving a token
     * @param tokenId token id that is being sent or minted
     * @param amount amount to be sent or minted
     */
    function transferFromOrMint(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external onlyOperator {
        if (exists(tokenId)) {
            safeTransferFrom(from, to, tokenId, amount, "");
        } else {
            _mint(to, tokenId, amount, bytes(""));
        }
    }

    /// @notice Set the base uri
    function setBaseURI(string memory newuri) external onlyOperator {
        _setURI(newuri);
    }

    /**
     * @dev See {ERC1155Supply-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
