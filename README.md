# Pixel Protocol
____

Pixel Protocol is inspired by [r/place](https://en.wikipedia.org/wiki/Place_(Reddit)), a collaborative online canvas experiment originally launched by Reddit in 2017 and revived in later years. In r/place, users could place a single colored pixel on a large shared canvas at set intervals, requiring cooperation and coordination to create larger images or artworks. The experiment became a viral phenomenon, showcasing the power of online communities to create, compete, and collaborate in real time.

Pixel Protocol brings this concept on-chain, allowing anyone to participate in a decentralized pixel war across multiple blockchains. Players can place pixels on a shared canvas, either for free (with a cooldown) or instantly by paying a small fee in USDC.

## Development

This is a Foundry project. You can find installation instructions for foundry, [here](https://book.getfoundry.sh/getting-started/installation). Clone the repository and run the following commands:

### Install

```shell
$ forge install
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Deploy

```shell
$ forge script script/PixelProtocol.s.sol:PixelProtocolScript --rpc-url <rpc-url> --account <account-name> --broadcast
```

**Note:** make sure the USDC address is correct in the script before deploying!

## Documentation

The `PixelProtocol.sol` contains the main API to play the Pixel war.
- `placePixel`: Place a pixel on the main canva. This action triggers a cooldown everyone has to wait before being able to call it again.
- `placePixelWithUSDC`: ace a pixel on the main canva by paying a small fee in USDC. This action doesn't trigger any cooldown and can be called at any time. However, the user needs to approve the pixelProtocol contract to transfer the USDC.

The contract has a permission system for the important settings and withdraw the fees paid by the users.

## Feedback

Please open issues or PRs on this repositories for any feedback.