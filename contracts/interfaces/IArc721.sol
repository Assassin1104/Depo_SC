// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IArc721 is IERC721 {
    function transferFromOrMint(
        address,
        address,
        uint256
    ) external;
}
