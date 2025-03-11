const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BookStorage", function () {
    let bookStorage, owner;

    beforeEach(async function () {
        [owner] = await ethers.getSigners();
        const bookStorageDeploy = await ethers.getContractFactory("BookStorage");
        bookStorage = await bookStorageDeploy.connect(owner).deploy();
    });

    it("Должен добавлять книгу", async function () {
        await bookStorage.addBook("1984", "George Orwell", 328, "Dystopia", 1949, ethers.parseEther("0.1"));

        const book = await bookStorage.estimateGas.getBook(0);
        expect(book[0]).to.equal("1984");
        expect(book[1]).to.equal("George Orwell");
        expect(book[2]).to.equal(328);
        expect(book[3]).to.equal("Dystopia");
        expect(book[4]).to.equal(1949);
        expect(book[5]).to.equal(ethers.parseEther("0.1"));
    });

    it("Должен корректно считать среднее количество страниц", async function () {
        await bookStorage.addBook("Book1", "Author1", 100, "Genre1", 2000, ethers.parseEther("0.05"));
        await bookStorage.addBook("Book2", "Author2", 200, "Genre2", 2010, ethers.parseEther("0.1"));
        await bookStorage.addBook("Book3", "Author3", 300, "Genre3", 2020, ethers.parseEther("0.15"));

        const avgPages = await bookStorage.averagePageCount();
        expect(avgPages).to.equal(200);
    });

    it("Должен корректно считать общую стоимость книг", async function () {
        await bookStorage.addBook("Book1", "Author1", 100, "Genre1", 2000, ethers.parseEther("0.05"));
        await bookStorage.addBook("Book2", "Author2", 200, "Genre2", 2010, ethers.parseEther("0.1"));
        await bookStorage.addBook("Book3", "Author3", 300, "Genre3", 2020, ethers.parseEther("0.15"));

        const totalCost = await bookStorage.totalCost();
        expect(totalCost).to.equal(ethers.parseEther("0.3"));
    });

    it("Должен выбрасывать ошибку при доступе к несуществующей книге", async function () {
        await expect(bookStorage.getBook(0)).to.be.revertedWith("Index out of bounds");
    });
});
