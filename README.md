# DeLP - Decentralized Learning Platform

### Table of Contents
- [Introduction](#introduction)
- [DeLT Token Contract](#1-delt-token-contract)
- [Quadratic Funding Contract](#2-quadratic-funding-contract)
- [Soulbound Certificate Contract](#3-soulbound-certificate-contract)
- [Course Management Contract](#4-course-management-contract)
***
## Introduction
DeLP, short for Decentralized Learning Platform, is a blockchain-based platform designed to revolutionize the world of education. By utilizing blockchain technology, DeLP aims to enhance the security, transparency, and accessibility of educational services. These smart contracts serve as the foundation of the DeLP ecosystem, providing essential functionalities for managing courses, issuing certificates, and facilitating quadratic funding for educational projects.

***
***
## Contracts Overview

### 1. DeLT Token Contract

- The DeLT token is the native cryptocurrency of the DeLP platform.
- `DeLT.sol` is an ERC20 token compliant with the Ethereum standard.
- The contract is responsible for creating and managing DeLT tokens, including initial token distribution and burning excess tokens.
- *Total Supply*: 1 billion (1e9) DeLT tokens with 18 decimal places.

***
### 2. Quadratic Funding Contract

#### Introduction to Quadratic Funding

Quadratic funding is a mechanism used to distribute matching funds among various projects based on the contributions received from donors. It aims to provide a fair and efficient way to support public goods or projects within a community. In this project, we utilize a specific variant of quadratic funding to allocate matching funds among participating projects.

### `QuadraticFunding.sol`

- This contract enables users to participate in quadratic funding for educational projects.
- It calculates matching funds for projects based on contributions from users, promoting community-driven support for education.
- Key functionalities include adding projects, contributing to projects, and enabling withdrawal of matching funds.

#### The Matching Funds Calculation
In this implementation of quadratic funding, the portion of funds allocated to each project is calculated using the following formula:

`Portion = (ContributionsCount * sqrt(ContributionsAmount))^2`

Where:

- ContributionsCount is the count of contributions (donations) made to the project.
- ContributionsAmount is a constant value associated with the project.

The formula computes the portion of matching funds by taking the square of the sum of the square roots of each contribution. This approach encourages a more equitable distribution of funds among projects that have received various levels of support.

##### Key Functions

- `calculatePortions()`

The function calculates the portions (shares) for each project. It iterates through the list of projects, computes the portion for each project based on their contributions, and accumulates the total denominator value. The result is an array of portions representing each project's share of matching funds.

- `updateMatchingFunds()`

The function is responsible for updating the matching funds for each project. It retrieves the total fund available for matching and the portions calculated using calculatePortions(). Then, it assigns matching funds to each project based on their computed portions. Projects with non-zero portions receive matching funds, and the number of projects with pending withdrawals is updated.

***
### 3. Soulbound Certificate Contract

#### Introduction to Soulbound Tokens

SoulBound Tokens are a unique type of digital asset that cannot be transferred or traded, ensuring their authenticity and exclusivity in various applications on the blockchain.

#### `SoulBoundCertificate.sol`

- Soulbound Certificates can represent academic achievements and are issued using this ERC721-compliant contract.
- This contract serves as a certificate issuance system using the Ethereum ERC721 standard. It introduces the concept of "Soul Bound Certificates," which have unique characteristics.
- These certificates are secured on the blockchain and cannot be transferred or approved for transfer, ensuring their authenticity.

##### Key Components

- ERC721 Overrides 
The contract overrides certain functions from the ERC721 standard, including `transferFrom`, `safeTransferFrom`, `approve`, and `setApprovalForAll`. These overrides essentially disallow the transfer and approval processes to ensure the non-transferable nature of the certificates.

- SoulBoundTokenLimitations Error
This is a custom error that is raised if anyone attempts to transfer or approve to transfer a Soul Bound Certificate. This error enforces the non-transferable nature of these certificates.

***
### 4. Course Management Contract

- `CourseManagement.sol` facilitates the creation and management of courses, student enrollment, and the issuance of certificates. It inherits the QuadraticFunding and SoulBoundCertificate contracts to access its needed functionalities.
- Quadratic funding is used to incentivize course creation and education-related projects. Each created course is added to the projects that can get funds from matching pool using quadratic funding mechanism.

***
***
## Getting Started

For detailed deployment and configuration instructions, please refer to the [Deployment Guide](deployment_guide.md) in this repository.

***
## Use Cases

- Educational Institutions: DeLP offers a transparent and secure platform for academic institutions to issue certificates and diplomas securely on the blockchain.

- Course Creators: Educators can create and manage courses on the DeLP platform, attracting support through quadratic funding and issuing blockchain-secured certificates.

- Students: Students can enroll in courses, contribute to educational projects, and earn certificates that are verifiable and tamper-proof.

***
## Future Development

The DeLP project is actively developing additional features, such as improved user interfaces, identity verification systems, and integration with other blockchain networks to enhance the educational experience further.

***
## Contributing

I welcome contributions from the community to help improve the DeLP platform. If you have ideas, bug fixes, or want to get involved, please feel free to submit pull requests or reach out to my social accounts.

***
## License

This project is licensed under the MIT License.

