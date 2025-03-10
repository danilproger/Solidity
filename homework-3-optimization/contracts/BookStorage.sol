// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract BookStorage {
    struct Book {
        string title;
        string author;
        uint256 pageCount;
        string genre;
        uint256 publicationYear;
        uint256 price;
    }

    Book[] public books;

    function addBook(
        string memory title,
        string memory author,
        uint256 pageCount,
        string memory genre,
        uint256 publicationYear,
        uint256 price
    ) public {
        books.push(Book(title, author, pageCount, genre, publicationYear, price));
    }

    function getBook(uint256 index) public view returns (
        string memory, string memory, uint256, string memory, uint256, uint256
    ) {
        require(index < books.length, "Index out of bounds");
        Book memory book = books[index];
        return (book.title, book.author, book.pageCount, book.genre, book.publicationYear, book.price);
    }

    function averagePageCount() public view returns (uint256) {
        require(books.length > 0, "No books available");
        uint256 totalPages = 0;
        for (uint256 i = 0; i < books.length; i++) {
            totalPages += books[i].pageCount;
        }
        return totalPages / books.length;
    }

    function totalCost() public view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < books.length; i++) {
            sum += books[i].price;
        }
        return sum;
    }
}