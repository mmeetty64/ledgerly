//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Ledgerly is ERC20("LedgerlyToken", "LED"){
    function decimals() public view virtual override returns (uint8) {
    return 4;
    }

    uint decim = 10**decimals();
    uint Time_start = block.timestamp;
    enum Role{User, Shop, Courier, Admin, Owner}
    enum Status{confirmation, delivery, completed, rejected}
    Product[] public Catalog;
    Order[] public orders;
    ShopData[] public reqShop;

    struct Review{
        uint grade;
        uint description;
        address user;
    }

    struct ShopData{
        string name;
        string description;
        string logo;
        bool status;
    }
    struct Product{
        uint id;
        string title;
        string description;
        uint tokenPrice;
        uint etherPrice;
        address shop;
        uint created_at;
    }

    struct Order{
        uint number;
        uint product;
        address user;
        Status status;
        uint created_at;
        string addDelivery;
    }

    mapping(uint => Review[]) public reviews;
    mapping(address => Role) public users;

    constructor(){
        address Owner = msg.sender;

        _mint(Owner, 21000000*decim);
    }
    //Создание заявки
    function createOrder(uint _product, string memory _addDelivery) public{
        orders.push(Order(orders.length, _product, msg.sender, Status.confirmation, block.timestamp, _addDelivery));
    }

    function rejectOrder(uint _number) public {
        orders[_number].status = Status.rejected;
    }


    //Вывод каталога
    function viewCatalog() public view returns(Product[] memory){
        return Catalog;
    }
    
}
