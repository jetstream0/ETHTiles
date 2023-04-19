// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

//Same as highest_bidder.sol but burns funds instead of allowing them to be withdrawn, and also allow expansion of width and height

interface IERC20 {
  function transferFrom(address sender, address recepient, uint256 amount) external returns (bool);
}

contract Tiles {
  bool public paused = false;
  uint32 public width;
  uint32 public height;
  address private immutable owner;
  IERC20 private immutable pay_token;

  event ChangePixel(
    address indexed _painter,
    uint32[2] indexed _coords,
    uint32 _color,
    uint256 _paid_amount
  );

  struct Pixel {
    uint32 color;
    address painter;
    uint256 paid_amount;
  }

  mapping(uint32 => mapping(uint32 => Pixel)) public pixels;

  constructor(address token, uint32 max_width, uint32 max_height) {
    owner = msg.sender;
    width = max_width;
    height = max_height;
    pay_token = IERC20(token);
  }

  modifier ownerOnly() {
    require(msg.sender == owner, "Not authorized, must be owner");
    _;
  }

  //setting pixel
	
  function setPixel(uint256 amount, uint32 x, uint32 y, uint32 color) public {
    //don't allow if paused
    require(!paused, "Coloring is paused");
    //make sure is within dimensions
    require(width > x, "x too large, outside dimensions");
    require(height > y, "y too large, outside dimensions");
    //check if amount is more than current amount (this also disallows paying 0 for pixel)
    require(pixels[y][x].paid_amount < amount, "Amount not enough");
    //try to send
    //caller must first call approve with the token and this contract
    bool send_success = pay_token.transferFrom(msg.sender, address(0x0000000000000000000000000000000000000000), amount);
    require(send_success, "Failed to send");
    //change pixel
    pixels[y][x] = Pixel(color, msg.sender, amount);
    //emit event
    emit ChangePixel(msg.sender, [x, y], color, amount);
  }

  //admin functions

  function clearPixel(uint32 x, uint32 y) public ownerOnly {
    //allow clearing even if paused
    //make sure is within dimensions
    require(width > x, "x too large, outside dimensions");
    require(height > y, "y too large, outside dimensions");
    //actually remove
    delete pixels[y][x];
  }

  function newDimensions(uint32 new_width, uint32 new_height) public ownerOnly {
    width = new_width;
    height = new_height;
  }

  function pause() external ownerOnly returns (bool) {
    paused = true;
    return paused;
  }

  function unpause() external ownerOnly returns (bool) {
    paused = false;
    return paused;
  }
}
