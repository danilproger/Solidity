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
    mapping(string => uint256) public bookPrices;

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

    function addBook(
        string calldata title,
        string calldata author,
        uint256 pageCount,
        string calldata genre,
        uint256 publicationYear,
        uint256 price
    ) external {
        books.push(Book(title, author, pageCount, genre, publicationYear, price));
        bookPrices[title] = price;
    }

    function updatePrice(string calldata title, uint256 newPrice) external {
        require(bookPrices[title] > 0, "Book not found");
        for (uint256 i = 0; i < books.length; i++) {
            if (keccak256(bytes(books[i].title)) == keccak256(bytes(title))) {
                books[i].price = newPrice;
                bookPrices[title] = newPrice;
                break;
            }
        }
    }

    function removeBook(uint256 index) external {
        require(index < books.length, "Index out of bounds");
        delete bookPrices[books[index].title];
        books[index] = books[books.length - 1];
        books.pop();
    }

    function buyBook(string calldata title) external payable {
        require(bookPrices[title] > 0, "Book not found");
        require(msg.value >= bookPrices[title], "Insufficient funds");
    }
}