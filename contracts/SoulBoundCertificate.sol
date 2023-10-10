// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title SoulBoundCertificate
 * @dev A contract for issuing Soul Bound Certificates using the ERC721 standard.
 * Soul Bound Certificates cannot be transferred or approved for transfer.
 */
contract SoulBoundCertificate is ERC721 {

    // Error message for attempting to transfer a Soul Bound Certificate
    error SoulBoundTokenLimitations();

    // Mapping to store metadata associated with each token
    mapping(uint256 => string) public tokensMetadata;

    // Array to store tokenIds of certificates
    // uint256[] public certificates;
    mapping(address => uint256[]) public ownerToCertificates;

    /**
     * @dev Constructor for the SoulBoundCertificate contract.
     * It initializes the contract with a name "SBCertificate" and a symbol "SBC".
     */
    constructor() ERC721("SBCertificate", "SBC") {}

    /**
     * @dev Function to burn (destroy) a Soul Bound Certificate.
     * @param tokenId The ID of the certificate to be burned.
     */
    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Invalid owner");
        super._burn(tokenId);
    }

    // Overrides for ERC721 transfer and approval functions with custom error
    function transferFrom(address, address, uint256) public pure override {
        revert SoulBoundTokenLimitations();
    }

    function safeTransferFrom(address, address, uint256, bytes memory) public pure override {
        revert SoulBoundTokenLimitations();
    }

    function approve(address, uint256) public pure override {
        revert SoulBoundTokenLimitations();
    }

    function setApprovalForAll(address, bool) public pure override {
        revert SoulBoundTokenLimitations();
    }

    /**
     * @dev Internal function to mint a Soul Bound Certificate.
     * @param to The address to which the certificate will be minted.
     * @param tokenId The ID of the certificate.
     * @param tokenMetadata The metadata associated with the certificate.
     * @return success A boolean indicating the success of the minting operation.
     */
    function mint(address to, uint256 tokenId, string memory tokenMetadata) internal returns (bool success) {
        _safeMint(to, tokenId);
        tokensMetadata[tokenId] = tokenMetadata;
        ownerToCertificates[to].push(tokenId);
        success = true;
    }
}
