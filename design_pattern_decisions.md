# Design Pattern Decisions
In the development of DeLP (Decentralized Learning Platform), we made several design pattern decisions to ensure the security, scalability, and efficiency of the platform. Below are some of the key design patterns we adopted:

***
## 1. Role-Based Access Control
Usage: Role-Based Access Control is used throughout our smart contracts.

Description: We implement a role-based access control system to manage permissions and access to various functions within our contracts. This design pattern restricts certain functionalities to specific roles, such as owner and course creators. It ensures that only authorized users can perform certain actions, enhancing security and access control.

***
## 2. Use ofExternal Libraries and Contracts 
In the development of the DeLP (Decentralized Learning Platform) project, we have made use of external libraries and smart contracts to enhance the functionality and security of our platform. These external components have been carefully selected to leverage established solutions, save development time, and ensure the reliability of our smart contracts.

### OpenZeppelin Contracts
One of the key libraries we have integrated into our project is the OpenZeppelin Contracts library. OpenZeppelin Contracts provide a collection of battle-tested smart contracts that follow best practices and security standards. In particular, we have utilized OpenZeppelin's implementation of the [ERC20](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol) token standard to create the DeLT token, our platform's native cryptocurrency, [ERC71](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol) token standard to create soulbount certificates, and [Owable](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol) access control library. 

By using OpenZeppelin Contracts, we benefit from:

Security: OpenZeppelin Contracts are thoroughly reviewed and audited, making them a trusted choice for implementing token functionality.
Efficiency: These contracts are optimized for gas usage and performance, ensuring a seamless experience for users.
Maintenance: OpenZeppelin actively maintains and updates its contracts to address security vulnerabilities and adapt to evolving best practices.

***
## 3. Withdrawal Pattern
Usage: The Withdrawal Pattern is employed in interactions with external contracts, such as transferring funds.

Description: To mitigate reentrancy vulnerabilities, we use the Withdrawal Pattern. This approach involves performing state changes after transferring funds to external contracts. By following this pattern, we minimize the risk of reentrancy attacks and ensure secure interactions with external contracts.

***
## 4. Immutable Contracts
Usage: Our smart contracts are designed to be immutable.

Description: We have chosen to make our contracts immutable, meaning that their code and functionality cannot be altered or upgraded after deployment. While contract upgradability can be advantageous, it also introduces potential security risks. By maintaining immutability, we prevent unintended changes to contract behavior, enhancing the security and predictability of our smart contracts.
