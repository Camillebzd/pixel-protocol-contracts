// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title  PixelProtocol
 * @author Camille Bouzerand, David Rayan
 * @notice Pixel war is back... on chains!
 */
contract PixelProtocol is Ownable {
    // =============================================================//
    //                             TYPE                             //
    // =============================================================//

    /// @dev Struct to represent a pixel on the canvas
    struct Pixel {
        uint24 color;
        address wallet;
        uint256 timestamp;
    }

    // =============================================================//
    //                            STORAGE                           //
    // =============================================================//

    /// @dev Constants for canvas dimension on x-axis
    uint256 public constant CANVAS_WIDTH = 500;
    /// @dev Constants for canvas dimension on y-axis
    uint256 public constant CANVAS_HEIGHT = 500;
    /// @dev Cooldown period for free pixel placement
    uint256 public COOLDOWN = 10 minutes; // not constant for MVP so we can change it
    /// @dev Fee for placing a pixel with USDC
    uint256 public constant USDC_FEE = 1_000_000; // 1 USDC (6 decimals)
    /// @dev USDC token contract address
    IERC20 public immutable usdc;
    /// @dev Mapping for canvas state: (x, y) => Pixel
    mapping(uint256 => mapping(uint256 => Pixel)) public canvas; // is it useful?
    /// @dev Mapping for user cooldowns: wallet => last placement timestamp
    mapping(address => uint256) public lastPlacement;

    // =============================================================//
    //                            EVENTS                            //
    // =============================================================//

    /// @dev Event emitted when a pixel is placed
    event PixelPlaced(
        uint256 indexed x,
        uint256 indexed y,
        uint24 color,
        address indexed wallet,
        uint256 timestamp
    );

    // =============================================================//
    //                            ERRORS                            //
    // =============================================================//

    /// @dev Error emitted when coordinates are invalid
    error InvalidCoordinates(uint256 x, uint256 y);
    /// @dev Error emitted when cooldown is active
    error CooldownActive(uint256 lastTime, uint256 cooldown);
    /// @dev Error emitted when USDC transfer fails
    error USDCTransferFailed();

    // =============================================================//
    //                          CONSTRUCTOR                         //
    // =============================================================//

    constructor(address initialOwner, address _usdc) Ownable(initialOwner) {
        usdc = IERC20(_usdc);
    }

    // =============================================================//
    //                             VIEW                             //
    // =============================================================//

    /// @notice Get the pixel information at the specified coordinates
    /// @param x The x coordinate of the pixel.
    /// @param y The y coordinate of the pixel.
    /// @return color The color of the pixel (24-bit RGB).
    /// @return wallet The address of the wallet that placed the pixel.
    /// @return timestamp The timestamp when the pixel was placed.
    function getPixel(
        uint256 x,
        uint256 y
    ) external view returns (uint24 color, address wallet, uint256 timestamp) {
        if (x >= CANVAS_WIDTH || y >= CANVAS_HEIGHT)
            revert InvalidCoordinates(x, y);

        Pixel memory pixel = canvas[x][y];
        return (pixel.color, pixel.wallet, pixel.timestamp);
    }

    // =============================================================//
    //                           EXTERNAL                           //
    // =============================================================//

    /// /!\ TESTING ONLY: Set cooldown
    function setCooldown(uint256 _cooldown) external /** onlyOwner() */ {
        COOLDOWN = _cooldown;
    }

    /// Place a pixel for free (subject to cooldown)
    /// @param x The x coordinate of the pixel.
    /// @param y The y coordinate of the pixel.
    /// @param color The color of the pixel (24-bit RGB).
    /// @dev Emits a PixelPlaced event.
    /// @dev This function allows users to place a pixel for free, but is subject to a cooldown period.
    function placePixel(
        uint256 x,
        uint256 y,
        uint24 color
    ) external {
        if (x >= CANVAS_WIDTH || y >= CANVAS_HEIGHT)
            revert InvalidCoordinates(x, y);

        uint256 lastTime = lastPlacement[msg.sender];

        if (lastTime != 0 && block.timestamp < lastTime + COOLDOWN) {
            revert CooldownActive(lastTime, COOLDOWN);
        }

        _updatePixel(x, y, color);
        lastPlacement[msg.sender] = block.timestamp;
    }

    /// Place a pixel by paying 1 USDC (bypasses cooldown)
    /// @param x The x coordinate of the pixel.
    /// @param y The y coordinate of the pixel.
    /// @param color The color of the pixel (24-bit RGB).
    /// @dev Emits a PixelPlaced event.
    /// @dev This function allows users to place a pixel by paying 1 USDC, bypassing the cooldown.
    /// Remember to approve the contract to spend USDC before calling this function.
    function placePixelWithUSDC(
        uint256 x,
        uint256 y,
        uint24 color
    ) external {
        if (x >= CANVAS_WIDTH || y >= CANVAS_HEIGHT)
            revert InvalidCoordinates(x, y);

        // Transfer 1 USDC from sender to contract
        bool transfered = usdc.transferFrom(msg.sender, address(this), USDC_FEE);
        if (!transfered) revert USDCTransferFailed();

        _updatePixel(x, y, color);
        // No cooldown update for paid placements
    }

    /// @notice Withdraw USDC from the contract
    /// @param to The address to withdraw USDC to.
    /// @param amount The amount of USDC to withdraw.
    /// @dev Only the contract owner can call this function.
    function withdrawUSDC(address to, uint256 amount) external onlyOwner() {
        // In MVP, no explicit owner
        require(usdc.transfer(to, amount), "USDC transfer failed");
    }

    // =============================================================//
    //                           INTERNAL                           //
    // =============================================================//

    // Internal function to update pixel and emit event
    function _updatePixel(uint256 x, uint256 y, uint24 color) internal {
        canvas[x][y] = Pixel({
            color: color,
            wallet: msg.sender,
            timestamp: block.timestamp
        });

        emit PixelPlaced(x, y, color, msg.sender, block.timestamp);
    }
}
