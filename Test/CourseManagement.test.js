const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

describe("DeLT Contract", function () {
    it("Should deploy DeLT contract", async function () {
        const DeLT = await ethers.getContractFactory("DeLT");
        const delt = await DeLT.deploy();
        // console.log(`This is the DeLT contract address: ${delt.target}`)
        expect(delt.target).to.not.equal(0);
        expect(await delt.name()).to.equal("DelToken");
        expect(await delt.symbol()).to.equal("DeLT");
    });
});

describe("CourseManagement Contract", function () {
    let delt;
    let courseManagement;

    beforeEach(async function () {
        const DeLT = await ethers.getContractFactory("DeLT");
        delt = await DeLT.deploy();

        const CourseManagement = await ethers.getContractFactory("CourseManagement");
        courseManagement = await CourseManagement.deploy(delt.target);
    });

    it("Should deploy CourseManagement contract", async function () {
        let deltAddress = await courseManagement.getDeLTAddress();
        expect(deltAddress).to.equal(delt.target);
    });

    it("Should add a new course and emit CourseAdded event", async function () {
        const startingCoursesCount = await courseManagement.getCoursesCount();
        const [owner, sender] = await ethers.getSigners()

        console.log(`The sender address: ${sender.address}`)

        const courseManagementConnected = courseManagement.connect(sender)
        const tx = await courseManagementConnected.addCourse(
            "Sample Course",
            ethers.parseEther("2"), // Registration fee in Wei (2 DeLT)
            "Certificate Metadata"
        );

        // Check the courses count increament
        const endingCoursesCount = await courseManagement.getCoursesCount();
        expect(startingCoursesCount + BigInt(1)).to.equal(endingCoursesCount);

        // Check the added course parameters
        const addedCourse = await courseManagement.courses(startingCoursesCount);

        expect(addedCourse.creator).to.equal(sender.address);
        expect(addedCourse.encryptedContentHash).to.equal("Sample Course");
        expect(addedCourse.registrationBaseFee).to.equal(ethers.parseEther("2"));
        expect(addedCourse.certificateMetadata).to.equal("Certificate Metadata");
        expect(addedCourse.active).to.equal(true);

        // Check the emitted event
        const courseAddedEvent = await getEvent(tx, "CourseAdded");
        expect(courseAddedEvent).to.not.be.undefined;
        expect(courseAddedEvent.args.creator).to.equal(sender.address)
    });

    describe("Enroll student in a course", function () {
        const courseFee = ethers.parseEther("2")    // Registration fee in Wei (2 DeLT)
        beforeEach(async function () {
            [owner, student] = await ethers.getSigners();

            await courseManagement.addCourse(
                "Sample Course",
                courseFee,
                "Certificate Metadata"
            );

            await delt.transfer(student, courseFee)
            console.log("transfer done")
        });

        it("Should not enroll a student in a course whitout approval", async function () {
            // Enroll a student
            await expect(courseManagement.connect(student)
                .enrollInCourse(
                    0,
                    courseFee
                )
            ).to.be.revertedWith("ERC20: insufficient allowance")
        });


        it("Should enroll a student in a course after DeLT approval", async function () {

            const courseManagementAddress = courseManagement.target
            await delt.connect(student).approve(courseManagementAddress, courseFee);
            console.log(`courseManagement address: ${courseManagementAddress}`)

            // Enroll the student in the course
            await courseManagement.connect(student).enrollInCourse(0, courseFee);

            // Get the status of the student after enrollment
            const studentStatus = await courseManagement.studentStatus(student.address, 0);
            const enrolledStatus = 1
            // expect(studentStatus).to.equal(enrolledStatus);
            assert.equal(studentStatus, enrolledStatus)
            // You can check various assertions here, e.g., the student's status, contributions, etc.
        });
    });

    it("Should not issue a certificate for a not passed course", async function () {
        [student, owner] = await ethers.getSigners();
        courseFee = ethers.parseEther("2")
        // Adding a new course
        await courseManagement.connect(owner).addCourse(
            "Sample Course",
            courseFee, // Registration fee in Wei (2 DeLT)
            "Certificate Metadata"
        );

        const courseManagementAddress = courseManagement.target
        await delt.connect(student).approve(courseManagementAddress, courseFee);

        // Enroll the student in the course
        await courseManagement.connect(student).enrollInCourse(0, courseFee);

        // Not issue a certificate for the passed course
        await expect(courseManagement.connect(student)
            .getCertificate(0)
        ).to.be.revertedWith("Student status must be passed")

    });

    // Helper function to get an event from a transaction
    async function getEvent(tx, event) {
        const receipt = await tx.wait();
        for (const log of receipt.logs) {
            const parsedLog = courseManagement.interface.parseLog(log);
            if (parsedLog.name === event) {
                return parsedLog;
            }
        }
        throw new Error(`Event ${event} not found in the transaction`);
    }

});


describe("Quadratic Funding Contract", function () {
    let amountToPool = ethers.parseEther("1000")
    const courseFee1 = ethers.parseEther("10")    // Registration fee in Wei (10 DeLT)
    const courseFee2 = ethers.parseEther("20")    // Registration fee in Wei (20 DeLT)

    beforeEach(async function () {
        [owner, courseCreator1, courseCreator2, student1, student2] = await ethers.getSigners();

        const DeLT = await ethers.getContractFactory("DeLT");
        delt = await DeLT.deploy();

        const CourseManagement = await ethers.getContractFactory("CourseManagement");
        courseManagement = await CourseManagement.deploy(delt.target);
        const courseManagementAddress = courseManagement.target

        // Adding new courses
        await courseManagement.connect(courseCreator1).addCourse(
            "Sample Course",
            courseFee1, // Registration fee in Wei (2 DeLT)
            "Certificate Metadata"
        );
        await courseManagement.connect(courseCreator2).addCourse(
            "Sample Course",
            courseFee2, // Registration fee in Wei (2 DeLT)
            "Certificate Metadata"
        );

        // Transfer token to increase students balance
        await delt.transfer(student1, courseFee1)
        await delt.transfer(student2, courseFee1 + courseFee2)

        // Approve before enrollment
        await delt.connect(student1).approve(courseManagementAddress, courseFee1);
        await delt.connect(student2).approve(courseManagementAddress, courseFee1 + courseFee2);

        // Enroll the students in the courses
        await courseManagement.connect(student1).enrollInCourse(0, courseFee1);
        await courseManagement.connect(student2).enrollInCourse(0, courseFee1);
        await courseManagement.connect(student2).enrollInCourse(1, courseFee2);
    });

    it("Set owner address and count of contributions for added projects", async function () {

        const project1 = await courseManagement.projects(0)
        const project2 = await courseManagement.projects(1)

        const firstProjectOwner = project1.owner
        const secondProjectOwner = project2.owner

        const firstProjectContributions = project1.contributionsCount
        const secondProjectContributions = project2.contributionsCount

        expect(firstProjectOwner).to.equal(courseCreator1.address);
        expect(secondProjectOwner).to.equal(courseCreator2.address);
        expect(firstProjectContributions).to.equal(2);
        expect(secondProjectContributions).to.equal(1);
    })

    it("Increase matching pool correctly", async function () {
        const courseManagementAddress = courseManagement.target
        await delt.approve(courseManagementAddress, amountToPool)
        const startingMatchingPool = await courseManagement.matchingPool()
        await courseManagement.increaseMatchingPool(amountToPool)
        const endingMatchingPool = await courseManagement.matchingPool()
        expect(startingMatchingPool + amountToPool).to.equal(endingMatchingPool);
    })

    it("Just projet owner can withdraw matching fund", async function () {
        const courseManagementAddress = courseManagement.target
        await delt.approve(courseManagementAddress, amountToPool)
        await courseManagement.increaseMatchingPool(amountToPool)
        await courseManagement.toggleWithdrawFunds()
        await expect(courseManagement
            .withdrawMatchingFund(0)
        ).to.be.revertedWith("Only project owner can withdraw")
    })

})
