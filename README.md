# delp
DeLP - Decentralized Learning Platform Contracts

Introduction
DeLP, short for Decentralized Learning Platform, is a blockchain-based platform designed to revolutionize the world of education. By utilizing blockchain technology, DeLP aims to enhance the security, transparency, and accessibility of educational services. These smart contracts serve as the foundation of the DeLP ecosystem, providing essential functionalities for managing courses, issuing certificates, and facilitating quadratic funding for educational projects.

Contracts Overview

1. DeLT Token Contract (DeLT.sol):

- The DeLT token is the native cryptocurrency of the DeLP platform.
- It is an ERC20 token compliant with the Ethereum standard.
- The contract is responsible for creating and managing DeLT tokens, including initial token distribution and burning excess tokens.
- Total Supply: 1 billion (1e9) DeLT tokens with 18 decimal places.

2. Quadratic Funding Contract (QuadraticFunding.sol):

- This contract enables users to participate in quadratic funding for educational projects.
- It calculates matching funds for projects based on contributions from users, promoting community-driven support for education.
- Key functionalities include adding projects, contributing to projects, and enabling withdrawal of matching funds.

3. SoulBoundCertificate Contract (SoulBoundCertificate.sol):

- SoulBoundCertificates represent academic achievements and are issued using this ERC721-compliant contract.
- These certificates are secured on the blockchain and cannot be transferred or approved for transfer, ensuring their authenticity.

4. CourseManagement Contract (CourseManagement.sol):

- CourseManagement is an extension of the QuadraticFunding and SoulBoundCertificate contracts.
- It allows educators to create courses, manage enrollments, and issue certificates to students.
- Quadratic funding is used to incentivize course creation and education-related projects.

Getting Started

To interact with the DeLP platform, you'll need to deploy these contracts to the Ethereum blockchain. You can use tools like Truffle or Remix for contract deployment and management. Once deployed, users can connect their wallets to enroll in courses, contribute to projects, and earn certificates.
For detailed deployment and configuration instructions, please refer to the [Deployment Guide](deployment-guide.md) in this repository.

Use Cases

- Educational Institutions: DeLP offers a transparent and secure platform for academic institutions to issue certificates and diplomas securely on the blockchain.

- Course Creators: Educators can create and manage courses on the DeLP platform, attracting support through quadratic funding and issuing blockchain-secured certificates.

- Students: Students can enroll in courses, contribute to educational projects, and earn certificates that are verifiable and tamper-proof.

Future Development

The DeLP project is actively developing additional features, such as improved user interfaces, identity verification systems, and integration with other blockchain networks to enhance the educational experience further.

Contributing

I welcome contributions from the community to help improve the DeLP platform. If you have ideas, bug fixes, or want to get involved, please feel free to submit pull requests or reach out to my social accounts.


License

This project is licensed under the MIT License.

