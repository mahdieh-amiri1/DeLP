// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
import "./DeLT.sol";
import"./SoulBoundCertificate.sol";
import"./QuadraticFunding.sol";

/**
 * @title CourseManagement
 * @dev A contract for managing courses, enrollment, and certificates.
 */
contract CourseManagement is QuadraticFunding, SoulBoundCertificate {

    // Structure to represent a course
    struct Course {
        address creator;                // Address of the course creator
        string encryptedContentHash;    // IPFS hash of the encrypted course content
        uint256 registrationBaseFee;    // Minimum DeLT tokens required for registration
        string certificateMetadata;     // Metadata for the course certificate
        bool active;                    // Indicates if the course is active
    }

    // Mapping of course IDs to courses
    mapping(uint256 => Course) public courses;

    // Mapping of courses that enrolled by the student address
    mapping(address => mapping(uint256 => bool)) public enrollments;

    // Mapping of courses that passed by the student address
    mapping(address => mapping(uint256 => bool)) public studentPassedCourses;

    // Counter for generating unique course IDs
    uint256 private courseIdCounter;

    // Events
    event CourseAdded(uint256 indexed courseId, address indexed creator);
    event CourseEnrolled(uint256 indexed courseId, address indexed student);
    event CourseDeactivated(uint256 indexed courseId, address indexed owner);
    event CourseActivated(uint256 indexed courseId, address indexed owner);
    event CertificateIssued(uint256 indexed tokenId, address indexed student, uint256 indexed courseId);
    event CoursePassed(uint256 indexed courseId, address indexed student);
 
    // Modifiers
    modifier onlyCourseCreator (uint256 courseId) {
        require(courses[courseId].creator == msg.sender, "Invalid course creator");
        _;
    }
    
    /**
     * @dev Constructor for the CourseManagement contract.
     * @param _delToken Address of the DeLT token contract.
     */
    constructor(address _delToken) QuadraticFunding(_delToken) {
        // The constructor initializes the QuadraticFunding contract with the address of the DeLT token contract.
    }

    /**
     * @dev Function to add a new course.
     * @param encryptedContentHash IPFS hash of the encrypted course content.
     * @param registrationBaseFee Minimum DeLT tokens required for registration.
     * @param certificateMetadata Metadata for course certificates.
     */
    function addCourse(
        string memory encryptedContentHash, 
        uint256 registrationBaseFee, 
        string memory certificateMetadata
    ) external {
        require(registrationBaseFee > 0, "Registration fee must be greater than 0");
        uint256 courseId = courseIdCounter++;
        courses[courseId] = Course({
            creator: msg.sender,
            encryptedContentHash: encryptedContentHash,
            registrationBaseFee: registrationBaseFee,
            certificateMetadata: certificateMetadata,
            active: true
        });

        // Add this course to projects for quadratic funding
        addToMatchingProjects(courseId, registrationBaseFee);
        emit CourseAdded(courseId, msg.sender);
    }

    /**
     * @dev Function to enroll in a course by paying the registration fee.
     * @param courseId The ID of the course to enroll in.
     * @param tokenAmount The amount of DeLT tokens to be used for enrollment.
     */
    function enrollInCourse(uint256 courseId, uint256 tokenAmount) public {
        require(courseId < courseIdCounter, "Invalid Course ID");
        Course memory course = courses[courseId];
        require(course.active, "Course is not active");
        require(tokenAmount >= course.registrationBaseFee, "Insufficient Token Amount");
        uint256 amountToPool = tokenAmount - course.registrationBaseFee;

        if (amountToPool > 0){ 
            // Update matching pool
            increaseMatchingPool(amountToPool);
        }

        bool transferSuccess = _DeLT.transferFrom(msg.sender, course.creator, course.registrationBaseFee);
        require(transferSuccess, "Token transfer failed");
        enrollments[msg.sender][courseId]= true;
        // Add this enrollment to contributions of this course for quadratic funding
        addToContributions(courseId);
        emit CourseEnrolled(courseId, msg.sender);
    }

    // Function to deactivate a course
    function deactivateCourse(uint256 courseId) external onlyCourseCreator(courseId) {
        Course storage course = courses[courseId];
        require(course.active, "Course is not active");
        course.active = false;
        emit CourseDeactivated(courseId, msg.sender);
    }

    // Function to activate a course
    function activateCourse(uint256 courseId) external onlyCourseCreator(courseId) {
        Course storage course = courses[courseId];
        require(!course.active, "Course is already active");
        course.active = true;
        emit CourseActivated(courseId, msg.sender);
    }

    /**
     * @dev Function to update the encrypted content hash of a course.
     * @param courseId The ID of the course to update.
     * @param encryptedContentHash The new IPFS hash of the encrypted course content.
     */
    function updateCourseContent(uint256 courseId, string memory encryptedContentHash) external onlyCourseCreator(courseId) {
        // Store the IPFS hash of the encrypted course content
        courses[courseId].encryptedContentHash= encryptedContentHash;
    }

    /**
     * @dev Function to retrieve the encrypted content hash of a course.
     * @return encryptedContentHash The IPFS hash of the encrypted course content.
     */
    // Future implementation: This function will enctypt the symmetric key k by the sender's public key
    function getCourseContent(uint256 courseId) external view returns(string memory) {
        require(enrollments[msg.sender][courseId], "Student not enrolled");
        return courses[courseId].encryptedContentHash;
    }

    /**
     * @dev Function to mark a course as passed by a student.
     * @param courseId The ID of the course to mark as passed.
     * @param student The address of the student.
     */
    function updatePassedCourses(uint256 courseId, address student) external onlyCourseCreator(courseId) {
        require(enrollments[student][courseId], "Student not enrolled");
        // Indicates that the course creator logically signs the certificate issuance
        studentPassedCourses[student][courseId] = true;
        emit CoursePassed(courseId, student);
    }

    /**
     * @dev Function for a student to retrieve a certificate for a passed course.
     * @param courseId The ID of the course for which the certificate is requested.
     */
    function getCertificate(uint256 courseId) public {
        require(courseId < courseIdCounter, "Invalid Course ID");
        require(studentPassedCourses[msg.sender][courseId], "Course is not passed");        
        // Indicates that the student logically signs the certificate issuance
        issueCertificate(msg.sender, courseId);
    }

    /**
     * @dev Internal function to issue a certificate for a passed course to a specific student.
     * @param student The address of the student to issue the certificate to.
     * @param courseId The ID of the course for which the certificate is issued.
     */
    function issueCertificate(address student, uint256 courseId) internal {
        // Generate a unique tokenId for the certificate
        uint256 tokenId = uint256(keccak256(abi.encodePacked(student, courseId, block.timestamp)));
        string memory metadata = courses[courseId].certificateMetadata;
        bool mintSuccess = mint(student, tokenId, metadata);
        require(mintSuccess, "Token mint failed");
        emit CertificateIssued(tokenId, student, courseId);
    }

    /**
     * @dev Function to issue a certificate for a passed course that only course creator can call.
     * @param courseId The ID of the course for which the certificate is issued.
     */
    function issueCertificate(uint256 courseId) public onlyCourseCreator(courseId) {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(msg.sender, courseId, block.timestamp)));
        string memory metadata = courses[courseId].certificateMetadata;
        bool mintSuccess = mint(msg.sender, tokenId, metadata);
        require(mintSuccess, "Token mint failed");
        emit CertificateIssued(tokenId, msg.sender, courseId);
    }

    /**
     * @dev Function to withdraw funds from the contract's DeLT token balance.
     * @param amount The amount of DeLT tokens to withdraw.
     */
    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount <= balanceOf(address(this)), "Insufficient balance");
        matchingPool -= amount;
        bool transferSuccess = _DeLT.transfer(owner(), amount);
        require(transferSuccess, "Token transfer failed");
        emit FundsWithdrawed(amount, matchingPool);
    }
}

