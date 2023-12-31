## Getting Started

These instructions will guide you through setting up and running the DeLP project on your local machine for development and testing purposes.

### Prerequisites

Before you begin, make sure you have the following prerequisites installed on your machine:

- [Node.js](https://nodejs.org/)
- [Yarn](https://yarnpkg.com/)
- [Git](https://git-scm.com/)
- [Hardhat](https://hardhat.org/)

### Installing

1. Clone this repository:

```bash
git clone https://github.com/mahdieh-amiri1/delp.git
```

2. Navigate to the project directory:

  ```bash
  cd delp
   ```


3. Install project dependencies:

  ```bash
  yarn install
  ```

## Usage
### Local Development
To deploy and test the DeLP smart contracts on your local Ethereum environment:

1. Deploy the smart contracts:

  ```bash
  yarn hardhat deploy
  ```

  Or run following command in another terminal instance in the same directory:

  ```bash
  yarn hardhat node
  ```

Then run:

  ```bash
  yarn hardhat deploy --network localhost
  ```

2. Interact code using hardhat console: (2 * Ctrl+C to exit)

  ```bash
  yarn hardhat console
  ```

3. Run tests:

  ```bash
  yarn hardhat test
  ```

### Deployment to a Testnet
To deploy the DeLP smart contracts to a public testnet:

1. Set up your environment variables (.env).
  `ALCHEMY_RPC_URL` - Replace with your Alchemy or Infura RPC URL.
  `PRIVATE_KEY` - Replace with your Ethereum wallet's private key.

2. Deploy the smart contracts to the desired network. For example, to deploy on the Sepolia testnet:
(Make sure you have testnet Ether to pay for gas fees.)

  ```bash
  yarn hardhat deploy --network sepolia
  ```

## Front-End
[Front-end repository](https://github.com/mahdieh-amiri1/delp-front)

```bash
git clone https://github.com/mahdieh-amiri1/delp-front.git
```
Set up `constants.js` and `delt_constants.js` by replacing your deployed contract addresses.
You can install `Live Server` extension if you are using VSCode to run the `main.html` in browser.
