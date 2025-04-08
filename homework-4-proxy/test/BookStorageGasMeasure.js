const { ethers } = require("hardhat");

describe("BookStorage", function () {
    let bookStorage, owner, addr1;

    beforeEach(async function () {
        const bookStorageDeploy = await ethers.getContractFactory("BookStorage");
        [owner, addr1] = await ethers.getSigners();
        bookStorage = await bookStorageDeploy.deploy();
        await bookStorage.waitForDeployment();
    });

    it("Should add book", async function () {
        const tx = await bookStorage.addBook("1984", "George Orwell", 328, 0, 1949, ethers.parseEther("0.1"));
        const receipt = await tx.wait();
        console.log("Gas used for addBook:", receipt.gasUsed.toString());
    });

    it("Should get book", async function () {
        await bookStorage.addBook("Book1", "Author1", 100, 1, 2000, ethers.parseEther("0.05"));

        const tx = await bookStorage.getBook(0);
        const receipt = await tx.wait();
        console.log("Gas used for getBook:", receipt.gasUsed.toString());
    });

    it("Should update book price", async function () {
        await bookStorage.addBook("Book1", "Author1", 300, 1, 2020, ethers.parseEther("0.05"));

        const tx = await bookStorage.updatePrice(0, ethers.parseEther("0.2"));
        const receipt = await tx.wait();
        console.log("Gas used for updatePrice:", receipt.gasUsed.toString());
    });

    it("Should get average page count", async function () {
        await bookStorage.addBook("Book1", "Author1", 100, 1, 2000, ethers.parseEther("0.05"));
        await bookStorage.addBook("Book2", "Author2", 200, 2, 2010, ethers.parseEther("0.1"));
        await bookStorage.addBook("Book3", "Author3", 300, 3, 2020, ethers.parseEther("0.15"));

        const gasUsed = await bookStorage.averagePageCount.estimateGas();
        console.log("Gas used for averagePageCount:", gasUsed.toString());

        const tx = await bookStorage.averagePageCount();
        const receipt = await tx.wait();
        console.log("Gas used for averagePageCount:", receipt.gasUsed.toString());
    });

    it("Should count total cost", async function () {
        await bookStorage.addBook("Book1", "Author1", 100, 1, 2000, ethers.parseEther("0.05"));
        await bookStorage.addBook("Book2", "Author2", 200, 2, 2010, ethers.parseEther("0.1"));
        await bookStorage.addBook("Book3", "Author3", 300, 3, 2020, ethers.parseEther("0.15"));

        const gasUsed = await bookStorage.totalCost.estimateGas();
        console.log("Gas used for totalCost:", gasUsed.toString());

        const tx = await bookStorage.totalCost();
        const receipt = await tx.wait();
        console.log("Gas used for totalCost:", receipt.gasUsed.toString());
    });
});