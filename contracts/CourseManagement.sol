// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
import "./DeLT.sol";
import"./SoulBoundCertificate.sol";
import"./QuadraticFunding.sol";

contract CourseManagement is QuadraticFunding, SoulBoundCertificate {

    // Structure to represent a course
    struct Course {
        address creator;                // Address of the course creator
        // string title;                // Title of the course
        // string description;          // Description of the course
        string encryptedContentHash;    // IPFS hash of the encrypted course content
        uint256 registrationBaseFee;    // Minimum DeLT tokens required for registration
        string certificateMetadata;
        bool active;                    // Indicates if the course is active
    }

    // Mapping of course IDs to courses
    mapping(uint256 => Course) public courses;

    // Mapping of courses that enrolled by the student address
    mapping(address => mapping (uint256 => bool)) public enrollments;

    // Mapping of courses that passed by the student address
    mapping(address => mapping (uint256 => bool)) public studentPassedCourses;

    // Mapping of courses IDs to enrollments count
    // mapping(uint256 => uint256) public enrollmentsCount;

    // Counter for generating unique course IDs
    uint256 private courseIdCounter;

    // events
    event CourseAdded(uint256 indexed courseId, address indexed creator);
    event CourseEnrolled(uint256 indexed courseId, address indexed student);
    event CourseDeactivated(uint256 indexed courseId, address indexed owner);
    event CourseActivated(uint256 indexed courseId, address indexed owner);
    event CertificateIssued(uint256 indexed tokenId, address indexed student, uint256 indexed courseId);
    event CoursePassed(uint256 indexed courseId, address indexed student);
 
    // modifiers
    modifier onlyCourseCreator (uint256 courseId) {
        require(courses[courseId].creator == msg.sender, "Invalid course creator");
        _;
    }
    
    constructor(
    address _delToken
    // , address _soulBoundToken
    ) QuadraticFunding(_delToken) {
        // _DeLT = DeLT(_delToken);
        // _SBT = SBT(_soulBoundToken);
    }

    // Function to add a new course
    function addCourse(
        // string memory title, string memory description,
        string memory encryptedContentHash, uint256 registrationBaseFee, string memory certificateMetadata, uint256 enrolls) external {
        require(registrationBaseFee > 0, "Registration fee must be greater than 0");
        uint256 courseId = courseIdCounter++;
        courses[courseId] = Course({
            creator: msg.sender,
            // title: title,
            // description: description,
            encryptedContentHash: encryptedContentHash,
            registrationBaseFee: registrationBaseFee,
            certificateMetadata: certificateMetadata,
            active: true
        });

        addToMatchingProjects(courseId, registrationBaseFee);

        // enrollmentsCount[courseId] = enrolls; // Just for test
        contributionsCount[courseId] = enrolls;
        emit CourseAdded(courseId, msg.sender);
    }

    // Function to enroll in a course by paying the registration fee
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
        // enrollmentsCount[courseId]++;
        contributionsCount[courseId]++;
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

    function updateCourseContent(uint256 courseId, string memory encryptedContentHash) external onlyCourseCreator(courseId) {
        // Store the IPFS hash of the encrypted course content
        courses[courseId].encryptedContentHash= encryptedContentHash;
    }

    function getCourseContent(uint256 courseId) external view returns(string memory) {
        require(enrollments[msg.sender][courseId], "Student not enrolled");
        // Future implementation: This function will enctypt the symmetric key k by the sender's public key
        return courses[courseId].encryptedContentHash;
    }

    function updatePassedCourses(uint256 courseId, address student) external onlyCourseCreator(courseId) {
        require(enrollments[student][courseId], "Student not enrolled");
        // Means that the course creator sings the certificate issuance logically
        studentPassedCourses[student][courseId] = true;
        emit CoursePassed(courseId, student);
    }

    function getCertificate(uint256 courseId) public {
        require(courseId < courseIdCounter, "Invalid Course ID");
        require(studentPassedCourses[msg.sender][courseId], "Course is not passed");        
        // Means that the student sings the certificate issuance logically
        issueCertificate(msg.sender, courseId);
    }

    function issueCertificate(uint256 courseId) public onlyCourseCreator(courseId) {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(msg.sender, courseId, block.timestamp)));
        string memory metadata = courses[courseId].certificateMetadata;
        bool mintSuccess = mint(msg.sender, tokenId, metadata);
        require(mintSuccess, "Token mint failed");
        emit CertificateIssued(tokenId, msg.sender, courseId);
    }

    function issueCertificate(address student, uint256 courseId) internal {
        // Generate a unique tokenId for the certificate
        uint256 tokenId = uint256(keccak256(abi.encodePacked(student, courseId, block.timestamp)));
        string memory metadata = courses[courseId].certificateMetadata;
        bool mintSuccess = mint(student, tokenId, metadata);
        require(mintSuccess, "Token mint failed");
        emit CertificateIssued(tokenId, student, courseId);
    }

    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount <= balanceOf(address(this)), "Insufficient balance");
        matchingPool -= amount;
        bool transferSuccess = _DeLT.transfer(owner(), amount);
        require(transferSuccess, "Token transfer failed");
        emit FundsWithdrawed(amount, matchingPool);
    }
}

