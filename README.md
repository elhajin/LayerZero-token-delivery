# Table of Contents :

- [Table of Contents :](#table-of-contents-)
- [What is an Htoken❓](#what-is-an-htoken)
    - [Key Features:](#key-features)
- [Protocol architecture :](#protocol-architecture-)
  - [wrapper :](#wrapper-)
    - [1. Wrapping Process:](#1-wrapping-process)
    - [1.1. Wrap Function:](#11-wrap-function)
    - [1.2. Clone Function (Restricted to Delivery Contract):](#12-clone-function-restricted-to-delivery-contract)
    - [1.3. Token Agnosticism:](#13-token-agnosticism)
    - [2. Unwrapping Process:](#2-unwrapping-process)
    - [2.1. Unwrap Function:](#21-unwrap-function)
  - [The Wrapper Contract's sophisticated design and functions form the cornerstone of the protocol, providing users with a robust mechanism for cross-chain transformation while maintaining the integrity of their assets.](#the-wrapper-contracts-sophisticated-design-and-functions-form-the-cornerstone-of-the-protocol-providing-users-with-a-robust-mechanism-for-cross-chain-transformation-while-maintaining-the-integrity-of-their-assets)
  - [Htoken: Advanced ERC-20 with Cross-Chain Functionality](#htoken-advanced-erc-20-with-cross-chain-functionality)
  - [1. Cross-Chain Send and SendFrom Functions:](#1-cross-chain-send-and-sendfrom-functions)
    - [1.1. Send Function:](#11-send-function)
    - [1.2. Estimate Transfer Fee Function:](#12-estimate-transfer-fee-function)
    - [1.3. SendFrom Function:](#13-sendfrom-function)
  - [run tests :](#run-tests-)
  - [deployment :](#deployment-)
    - [Setup :](#setup-)
    - [deploy :](#deploy-)

# What is an [Htoken](./src/Htoken/Htoken.sol)❓

**Htoken**, short for Hawk Token, represents a revolutionary leap in decentralized finance (DeFi), offering token holders unparalleled cross-chain mobility and advanced functionalities.

At its core, an Htoken is a transformed version of any existing token, referred to as the "native token." Leveraging cutting-edge layer 0 technology, Htoken introduces a seamless and efficient cross-chain transfer mechanism. With just one transaction, Htoken holders can navigate across different blockchain ecosystems.

### Key Features:

1.  **Layer 0 Cross-Chain Transfer:**

Htoken harnesses layer 0 technology to simplify and expedite cross-chain transfers. This innovative approach enables users to effortlessly move their assets across different blockchain networks, all within a single transaction.

2.  **Wrap and Unwrap Mechanism:**

The process of transforming a native token into an Htoken is known as "wrapping." This action encapsulates the native token within the Hawk protocol, unlocking its cross-chain potential. Conversely, Htoken holders can opt to "unwrap" their tokens, converting them back to their native form. This unwrapping process is limited to the native chain where the original token contract resides, ensuring security and integrity.

3.  **Full ERC-20 Compatibility:**

Htoken is designed with full compatibility with the ERC-20 standard. It inherits all the familiar functionalities of an ERC-20 token, making it easy to integrate into existing DeFi applications and platforms. Additionally, Htoken incorporates specialized functions to facilitate cross-chain transfers, akin to the capabilities of other interoperable tokens.

4.  **Empowering Token Holders:**

Htoken holders gain unparalleled flexibility in navigating the evolving landscape of blockchain networks. Seeking optimal transaction fees, faster confirmation times, or specific network features becomes a seamless process. With the autonomy to choose the most suitable blockchain for their needs, Htoken holders redefine the possibilities of decentralized finance.

Unlock the potential of your tokens, transcend blockchain boundaries, and embrace a new era of financial flexibility with Htoken. Join us on this journey as we reshape the landscape of decentralized finance, introducing a seamless cross-chain experience with the power of layer 0 technology.

# Protocol architecture :

## wrapper :

The **Wrapper Contract** serves as a pivotal component of the protocol, orchestrating the seamless wrapping and unwrapping of native tokens to and from their corresponding Htoken forms. This intelligent contract not only facilitates the creation of Htokens but also ensures a secure and streamlined cross-chain experience for users.

### 1. Wrapping Process:

### 1.1. Wrap Function:

Users initiate the wrapping process by calling the `wrap` function, specifying the native token they wish to convert into an Htoken, along with the desired amount. Prior to wrapping, users must approve the Wrapper Contract to spend the specified amount of the native token. Upon receiving approval, the Wrapper Contract performs the following steps:

- Checks for the existence of an Htoken associated with the specified native token.
- If an Htoken exists, mints an equivalent amount of Htokens to the user.
- If no Htoken exists, creates a new Htoken by cloning and registering it with the native token. Only one Htoken can be created per native token.
- Assigns metadata to the newly created Htoken, naming it with an 'H' prefix before the native token name and symbol. For instance, if the native token is named "Circle USD" with the symbol "USDC," the Htoken is named "HCircle USD" with the symbol "HUSDC."

### 1.2. Clone Function (Restricted to Delivery Contract):

The Wrapper Contract includes a `clone` function, exclusively callable by the _Delivery_ contract, a key element we'll explore in the next section. This function enables the Delivery contract to create clones of Htokens when necessary, contributing to the protocol's efficiency and adaptability.

### 1.3. Token Agnosticism:

The Wrapper Contract is token-agnostic, supporting the wrapping of any ERC-20 token. However, it does not currently support ERC-20 tokens with fee-on-transfer mechanisms and rebasing tokens. Wrapping these token types may lead to potential user losses due to the unique characteristics of fee-on-transfer and rebasing mechanisms.

### 2. Unwrapping Process:

### 2.1. Unwrap Function:

When Htoken holders wish to retrieve their native tokens, they can call the `unwrap` function within the Wrapper Contract. This process results in the burning of Htokens and the subsequent transfer of native tokens back to the user. This operation must occur on the native chain where the original token contract resides, ensuring the protocol's security and integrity.

## The Wrapper Contract's sophisticated design and functions form the cornerstone of the protocol, providing users with a robust mechanism for cross-chain transformation while maintaining the integrity of their assets.

## Htoken: Advanced ERC-20 with Cross-Chain Functionality

The **Htoken** introduces enhanced ERC-20 functionalities tailored for cross-chain transfers, providing users with a powerful mechanism to send and receive tokens seamlessly across different blockchain networks.

## 1. Cross-Chain Send and SendFrom Functions:

### 1.1. Send Function:

The `send` function allows users to initiate cross-chain transfers of Htokens to an address located on a different blockchain. This function requires the following parameters:

- **Destination ChainId:** The unique identifier of the destination blockchain.
- **To Address:** The recipient's address on the destination chain.
- **Amount:** The quantity of Htokens to be sent.

To facilitate the cross-chain transfer, users must include a certain amount of native tokens (ETH or the native token of the local chain) as fees. The fee is crucial for covering gas costs in the distination chain. If the provided fee is insufficient, the call will revert; if it exceeds the required amount, users will receive a refund of the surplus.

### 1.2. Estimate Transfer Fee Function:

To determine the required fee for a cross-chain transfer, users can utilize the `estimateTransferFee` function. This function provides an estimate of the native token fee needed for a successful cross-chain transfer, depending on the local chain's native token. The parameters include:

- **Pay in ZRO (Zero Utility Token):** A boolean indicating whether the fee should be paid in the protocol's utility token (ZRO).
- **Destination ChainId:** The unique identifier of the destination blockchain.
- **To Address:** The recipient's address on the destination chain.
- **Amount:** The quantity of Htokens to be sent.

### 1.3. SendFrom Function:

Similar to the `send` function, `sendFrom` allows a designated spender to initiate cross-chain transfers. The spender must be approved to spend Htokens on behalf of the sender through the typical ERC-20 approval process.

-

## run tests :

```sh
 forge test -vvv
```

> `NOTICE` : you have to make sure that [test_addRemoteAddress](./src/delivery/delivery.sol#L104) function uncommented.

## deployment :

### Setup :

- there is three contract that should be deployed in all chains you wanna support.
- the deploment [script](./script/deploy.sol) will deploy and verify the contracts in the running chain. the script is getting the configration and the layerZero endpoint contract in each chain from [refrences.json](./L0_refrences/refrences.json) file.
- before start deployment make sure to :
  - fill .env file (see [.envExample](./.envExample)).
  - store your private key using `cast` under the name of `pk` by running :
    ```sh
    cast wallet import pk --private-key <your private key>
    ```
    this will ask you for a password to encrypt your private key. and you will need to type the password for each transaction broadcast .
  - export the address of the given private key under the name of sender :
    ```sh
      export sender=<address of the given private key>
    ```

### deploy :

now everything is good. let's deploy the contracts to testnets :

- deploy to sepolia :

```sh
 make deploy_sepolia
```

- deploy to mumbai :

```sh
 make deploy_mumbai
```

- deploy to arbitrum :

```sh
  make deploy_arb
```

> if you wanna Simulate the deployment ina fork before actualy deploy it to testnet .. just add `_local` ex :
>
> ```sh
>   make deploy_sepolia_local
> ```

> also make sure you have enough native token for each chain .. for deployment.

- now you have to config the delivery contract in each chain :

  - configurate in sepolia delivery :

    ```sh
      make config_sepolia
    ```

  - configurate mumbai delivery :

    ```sh
    make config_mumbai
    ```

  - configurate arbitrum delivery :

    ```sh
    make config_arb
    ```

- if you have some `chainlink` token Faucet in the sender address you can try to interact with the protocol by running :
  ```sh
    make wrap_and_send
  ```
