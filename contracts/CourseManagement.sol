// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SoulBoundCertificate.sol";
import "./QuadraticFunding.sol";

/**
 * @title CourseManagement
 * @dev A contract for managing courses, enrollment, and certificates.
 */
contract CourseManagement is QuadraticFunding, SoulBoundCertificate {
    
    // Counter for generating unique course IDs
    uint256 private courseIdCounter;

    // Mapping of course IDs to courses
    mapping(uint256 => Course) public courses;
    mapping(address => mapping(uint256 => Status)) public studentStatus;

    // Events
    event CourseAdded(uint256 indexed courseId, address indexed creator);
    event CourseEnrolled(uint256 indexed courseId, address indexed student);
    event CourseDeactivated(uint256 indexed courseId, address indexed owner);
    event CourseActivated(uint256 indexed courseId, address indexed owner);
    event CertificateIssued(
        uint256 indexed tokenId,
        address indexed student,
        uint256 indexed courseId
    );
    event CoursePassed(uint256 indexed courseId, address indexed student);

    // Modifiers
    modifier onlyCourseCreator(uint256 courseId) {
        require(
            courses[courseId].creator == msg.sender,
            "Invalid course creator"
        );
        _;
    }

    // Structure to represent a course
    struct Course {
        address creator;             // Address of the course creator
        string encryptedContentHash; // IPFS hash of the encrypted course content (The course content will not be visible to public)
        uint256 registrationBaseFee; // Minimum DeLT tokens required for registration
        string certificateMetadata;  // Metadata for the course certificate
        bool active;                 // Indicates if the course is active
    }

    // An enum to represent the student status related to each course
    enum Status {NULL, ENROLLED, PASSED, CERTIFIED}

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
        require(
            registrationBaseFee > 0,
            "Registration fee must be greater than 0"
        );
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
    function enrollInCourse(uint256 courseId, uint256 tokenAmount) external {
        require(courseId < courseIdCounter, "Invalid Course ID");
        // require(!enrollments[msg.sender][courseId], "Student is already enrolled");
        require(studentStatus[msg.sender][courseId] < Status.ENROLLED , "Student is already enrolled");
        Course memory course = courses[courseId];
        require(course.active, "Course is not active");
        require(
            tokenAmount >= course.registrationBaseFee,
            "Insufficient Token Amount"
        );
        uint256 amountToPool = tokenAmount - course.registrationBaseFee;

        if (amountToPool > 0) {
            // Update matching pool
            increaseMatchingPool(amountToPool);
        }

        bool transferSuccess = _DeLT.transferFrom(
            msg.sender,
            course.creator,
            course.registrationBaseFee
        );
        require(transferSuccess, "Token transfer failed");
        studentStatus[msg.sender][courseId] = Status.ENROLLED;
        // enrollments[msg.sender][courseId] = true;
        // Add this enrollment to contributions of this course for quadratic funding
        addToContributions(courseId);        
        emit CourseEnrolled(courseId, msg.sender);
    }

    // Function to deactivate a course
    function deactivateCourse(uint256 courseId)
        external
        onlyCourseCreator(courseId)
    {
        Course storage course = courses[courseId];
        require(course.active, "Course is not active");
        course.active = false;
        emit CourseDeactivated(courseId, msg.sender);
    }

    // Function to activate a course
    function activateCourse(uint256 courseId)
        external
        onlyCourseCreator(courseId)
    {
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
    function updateCourseContent(
        uint256 courseId,
        string memory encryptedContentHash
    ) external onlyCourseCreator(courseId) {
        // Store the IPFS hash of the encrypted course content
        courses[courseId].encryptedContentHash = encryptedContentHash;
    }

    // Future implementation: 
    // Combining symmetric and asymmetric cryptographys!
    // This function will encrypt the secret key of symmetric encryption (k) by the sender's public key
    // Then will stored in the ipfs
    // The the sender will get able to decrypt the course content hash (stored in ipfs also)
    // Symmetric encryption (AES) will be handled off-chain because of k security
    function getCourseContentAccess(uint256 courseId) external view {
        require(studentStatus[msg.sender][courseId] > Status.NULL, "Invalid access");
        require(courses[courseId].active, "Course is not active");
        // Rest of the code
    }

    /**
     * @dev Function to mark a course as passed by a student.
     * @param courseId The ID of the course to mark as passed.
     * @param student The address of the student.
     */
    function updatePassedCourses(uint256 courseId, address student)
        external
        onlyCourseCreator(courseId)
    {
        // require(enrollments[student][courseId], "Student not enrolled");
        require(studentStatus[student][courseId] == Status.ENROLLED , "Student status must be enrolled");

        // Indicates that the course creator logically signs the certificate issuance
        // studentPassedCourses[student][courseId] = true;
        studentStatus[student][courseId] = Status.PASSED;
        emit CoursePassed(courseId, student);
    }

    /**
     * @dev Function for a student to retrieve a certificate for a passed course.
     * @param courseId The ID of the course for which the certificate is requested.
     */
    // Indicates that the student logically signs the certificate issuance
    function getCertificate(uint256 courseId) external {
        require(courseId < courseIdCounter, "Invalid Course ID");
        // require(!gotCertified[msg.sender][courseId], "Student is already certified");
        // require(
        //     studentPassedCourses[msg.sender][courseId],
        //     "Course is not passed"
        // );
        require(studentStatus[msg.sender][courseId] == Status.PASSED, "Student status must be passed");
        
        // Issue certificate:
        uint256 tokenId = uint256(
            keccak256(abi.encodePacked(msg.sender, courseId, block.timestamp))
        );
        string memory metadata = courses[courseId].certificateMetadata;
        bool mintSuccess = mint(msg.sender, tokenId, metadata);
        require(mintSuccess, "Token mint failed");
        studentStatus[msg.sender][courseId] = Status.CERTIFIED;
        emit CertificateIssued(tokenId, msg.sender, courseId);
    }

    /**
     * @dev Function to issue a certificate for a passed course that only course creator can call.
     * @param courseId The ID of the course for which the certificate is issued.
     * @param student The address of the student to issue the certificate to.
     */
    function issueCertificate(uint256 courseId, address student)
        external
        onlyCourseCreator(courseId)
    {
        // require(
        //     studentPassedCourses[student][courseId],
        //     "Course is not passed"
        // );
        // require(!gotCertified[student][courseId], "Student is already certified");
        require(studentStatus[student][courseId] == Status.PASSED, "Student status must be passed");

        uint256 tokenId = uint256(
            keccak256(abi.encodePacked(student, courseId, block.timestamp))
        );
        string memory metadata = courses[courseId].certificateMetadata;
        bool mintSuccess = mint(student, tokenId, metadata);
        require(mintSuccess, "Token mint failed");
        // gotCertified[msg.sender][courseId] == true;
        studentStatus[student][courseId] = Status.CERTIFIED;
        emit CertificateIssued(tokenId, student, courseId);
    }
}
