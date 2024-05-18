//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ToColor.sol";

contract OhPandaMEME is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Strings for uint160;
    using ToColor for bytes3;

    uint256 private _nextTokenId;

    mapping(uint256 => bytes3) public color;
    mapping(uint256 => uint256) public mouthWidth;

    uint256 mintDeadline = block.timestamp + 3650 days;

    constructor() ERC721("OhPandaMEME", "OPM") {}

    function mintItem() public returns (uint256) {
        require(block.timestamp < mintDeadline, "DONE MINTING");

        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);

        bytes32 predictableRandom = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                msg.sender,
                address(this),
                block.chainid,
                tokenId
            )
        );

        color[tokenId] =
            bytes2(predictableRandom[0]) |
            (bytes2(predictableRandom[1]) >> 8) |
            (bytes3(predictableRandom[2]) >> 16);
        mouthWidth[tokenId] =
            9 +
            ((50 * uint256(uint8(predictableRandom[3]))) / 255);

        return tokenId;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "!exist");

        string memory name = string(
            abi.encodePacked("Oh Pandas MEME #", id.toString())
        );
        string memory description = string(
            abi.encodePacked(
                "This Oh Pandas MEME borns with genes of color #",
                color[id].toColor(),
                " and size ",
                mouthWidth[id].toString(),
                "!!!"
            )
        );

        string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

        (
            string memory leftEarColor,
            string memory rightEarColor,
            string memory faceStrokeColor1,
            string memory faceStrokeColor2,
            string memory leftEyeColor,
            string memory rightEyeColor,
            string memory noseColor,
            string memory mouthColor,
            uint256 mouthSize,
            uint256 earSize,
            uint256 noseSize,
            bool tiltHead
        ) = getPropertiesById(id);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '","description":"',
                                description,
                                '","external_url":"https://ohpandas.com/token/',
                                id.toString(),
                                '","attributes":[{"trait_type":"left ear color","value":"#',
                                leftEarColor,
                                '"},{"trait_type":"right ear color","value":"#',
                                rightEarColor,
                                '"},{"trait_type":"tilt head","value":"',
                                tiltHead ? 'yes(1%)' : 'no(99%)',
                                '"},{"trait_type":"facial outline color","value":"#',
                                faceStrokeColor1,
                                ",",
                                faceStrokeColor2,
                                '"},{"trait_type":"left eye color","value":"#',
                                leftEyeColor,
                                '"},{"trait_type":"right eye color","value":"#',
                                rightEyeColor,
                                '"},{"trait_type":"nose color","value":"#',
                                noseColor,
                                '"},{"trait_type":"mouth color","value":"#',
                                mouthColor,
                                '"},{"trait_type":"mouth size","value":"',
                                mouthSize.toString(),
                                '"},{"trait_type":"ear size","value": "',
                                earSize.toString(),
                                '"},{"trait_type":"nose size","value": "',
                                noseSize.toString(),
                                '"}],"owner":"',
                                (uint160(ownerOf(id))).toHexString(20),
                                '","image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    // function generateSVGofTokenById(uint256 id) internal view returns (string memory) {
    function generateSVGofTokenById(
        uint256 id
    ) internal view returns (string memory) {
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink">',
                renderTokenById(id),
                "</svg>"
            )
        );
        return svg;
    }

    // properties of the token of id
    function getPropertiesById(
        uint256 id
    )
        public
        view
        returns (
            string memory leftEarColor,
            string memory rightEarColor,
            string memory faceStrokeColor1,
            string memory faceStrokeColor2,
            string memory leftEyeColor,
            string memory rightEyeColor,
            string memory noseColor,
            string memory mouthColor,
            uint256 mouthSize,
            uint256 earSize,
            uint256 noseSize,
            bool tiltHead
        )
    {
        uint24 theColor = uint24(color[id]);
        leftEarColor = bytes3(theColor).toColor();

        mouthSize = mouthWidth[id];
        earSize = 20 + mouthSize / 2;
        noseSize = 17 + mouthSize / 8;

        tiltHead = (id % 100) == 0;

        unchecked {
            rightEarColor = bytes3(theColor + 0xF5F7E3).toColor();
            faceStrokeColor1 = bytes3(theColor + 0xDDD5ED).toColor();
            faceStrokeColor2 = bytes3(theColor + 0xDDD5ED + 0x693909).toColor();
            leftEyeColor = bytes3(theColor + 0xBCB5DD).toColor();
            rightEyeColor = bytes3(theColor + 0x9079A8).toColor();
            noseColor = bytes3(theColor + 0x625068).toColor();
            mouthColor = bytes3(theColor + 0x8D64A8).toColor();
        }
    }

    // Visibility is `public` to enable it being called by other contracts for composition.
    function renderTokenById(uint256 id) public view returns (string memory) {
        (
            string memory leftEarColor,
            string memory rightEarColor,
            string memory faceStrokeColor1,
            string memory faceStrokeColor2,
            string memory leftEyeColor,
            string memory rightEyeColor,
            string memory noseColor,
            string memory mouthColor,
            uint256 mouthSize,
            uint256 earSize,
            uint256 noseSize,
            bool tiltHead
        ) = getPropertiesById(id);

        string memory render = string(
            abi.encodePacked(
                // face stroke gradient defs
                '<defs><linearGradient id="ohGradient" gradientTransform="rotate(90)">',
                '<stop offset="5%" stop-color="#',
                faceStrokeColor1,
                '"/>',
                '<stop offset="50%" stop-color="#',
                faceStrokeColor2,
                '"/>',
                '<stop offset="95%" stop-color="#',
                faceStrokeColor1,
                '"/>',
                "</linearGradient></defs>",
                "<g>",
                // left ear
                '<circle cx="90" cy="80" r="',
                earSize.toString(),
                '" fill="#',
                leftEarColor,
                '" shape-rendering="geometricPrecision">',
                '<animateTransform attributeName="transform" type="translate" dur="1.5s" values="0 -3;0 6;0 -3;" repeatCount="indefinite"/>',
                "</circle>",
                // right ear
                '<circle cx="210" cy="80" r="',
                earSize.toString(),
                '" fill="#',
                rightEarColor,
                '" shape-rendering="geometricPrecision">',
                '<animateTransform attributeName="transform" type="translate" dur="1.75s" values="0 -3;0 6;0 -3;" repeatCount="indefinite"/>',
                "</circle>",
                "<g>",
                // head(face)
                '<circle cx="150" cy="150" r="97" stroke="',
                "url('#ohGradient')",
                '" stroke-width="6.38" fill="white" shape-rendering="geometricPrecision">',
                '<animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 150 150" to="360 150 150" dur="6s" repeatCount="indefinite"/>',
                "</circle>",
                "<g>",
                // left eye
                '<circle cx="115" cy="125" r="27.04" fill="#',
                leftEyeColor,
                '" shape-rendering="geometricPrecision"></circle>',
                '<circle cx="115" cy="125" r="10.32" fill="white" shape-rendering="geometricPrecision">',
                '<animate attributeName="r" values="15;13;10;15" dur="10s" repeatCount="indefinite"/>',
                '</circle>',
                // right eye
                '<circle cx="185" cy="125" r="27.04" fill="black" shape-rendering="geometricPrecision"></circle>',
                '<circle cx="185" cy="125" r="10.32" fill="#',
                rightEyeColor,
                '" shape-rendering="geometricPrecision">',
                '<animate attributeName="fill" values="#',
                rightEyeColor,
                ";red;#",
                rightEyeColor,
                '" dur="1s" repeatCount="indefinite"/>',
                '<animate attributeName="r" values="15;13;10;15" dur="10s" repeatCount="indefinite"/>',
                "</circle>",
                '<circle cx="185" cy="125" r="6.38" fill="black" shape-rendering="geometricPrecision"></circle>',
                // nose
                '<circle cx="150" cy="170" r="',
                noseSize.toString(),
                '" fill="#',
                noseColor,
                '" shape-rendering="geometricPrecision">',
                '<animateTransform attributeName="transform" type="translate" dur="2.5s" values="0 -1;0 2;0 -1;" repeatCount="indefinite"/>',
                "</circle>",
                // mouse
                '<ellipse cx="150" cy="210" rx="',
                mouthSize.toString(),
                '" ry="9.09" style="fill:#',
                mouthColor,
                ';stroke:black;stroke-width:3.94" shape-rendering="geometricPrecision">',
                '<animate attributeName="rx" values="',
                mouthSize.toString(),
                ";10;",
                mouthSize.toString(),
                '" dur="5s" repeatCount="indefinite"/>',
                "</ellipse>",
                '<animateTransform attributeName="transform" type="translate" dur="5s" values="0 -2;0 4;0 -2;" repeatCount="indefinite"/>',
                "</g>",
                '<animateTransform attributeName="transform" type="translate" dur="3.75s" values="0 -3;0 6;0 -3;" repeatCount="indefinite"/>',
                "</g>",
                tiltHead
                    ? '<animateTransform attributeName="transform" attributeType="XML" type="rotate" values="-10 150 150;10 150 150;-10 150 150" dur="6s" repeatCount="indefinite"/>'
                    : "",
                "</g>"
            )
        );

        return render;
    }
}
