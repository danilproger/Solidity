// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract BookStorageOptimized {
    struct Book {
        string title;
        string author;
        uint256 price;
        uint16 pageCount;
        uint16 genre;
        uint16 publicationYear;
    }

    mapping(uint256 => Book) public books;
    uint256 public booksCount;

    function addBook(
        string calldata title,
        string calldata author,
        uint16 pageCount,
        uint16 genre,
        uint16 publicationYear,
        uint256 price
    ) public {
        books[booksCount++] = Book(title, author, price, pageCount, genre, publicationYear);
    }

    function getBook(uint256 index) public returns (
        string memory, string memory, uint16, uint16, uint16, uint256
    ) {
        require(index < booksCount, "Index out of bounds");
        Book memory book = books[index];
        return (book.title, book.author, book.pageCount, book.genre, book.publicationYear, book.price);
    }

    function averagePageCount() public returns (uint256) {
        if (booksCount == 0) {
            return 0;
        }
        unchecked {
            uint256 totalPages = 0;
            for (uint256 i = 0; i < booksCount; i++) {
                totalPages += books[i].pageCount;
            }
            return totalPages / booksCount;
        }
    }

    function totalCost() public returns (uint256) {
        unchecked {
            uint256 sum = 0;
            for (uint256 i = 0; i < booksCount; i++) {
                sum += books[i].price;
            }
            return sum;
        }
    }

    function updatePrice(uint256 index, uint256 newPrice) public {
        require(index < booksCount, "Index out of bounds");
        Book storage book = books[index];
        book.price = newPrice;
    }
}