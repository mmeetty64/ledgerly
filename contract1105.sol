//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Ledgerly is ERC20("LedgerlyToken", "LED"){
    function decimals() public view virtual override returns (uint8) {
    return 4;
    }

    uint decim = 10**decimals();
    uint Time_start = block.timestamp;
    uint tokenPrice = 0.00034 ether;
    enum Role{User, Shop, Courier, Admin, Owner}
    enum Status{confirmation, delivery, completed, rejected}
    enum Paying{ethereum, token}
    Product[] public Catalog;
    Order[] public orders;
    Shop[] public shops;
    Shop[] public reqShop;

    struct Review{
        uint grade;
        string description;
        address user;
    }

    struct Product{
        uint id;
        string title;
        string description;
        uint tokenPrice;
        address shop;
        uint amount;
        uint created_at;
    }

    struct Order{
        uint number;
        uint product;
        uint amount;
        address user;
        Status status;
        uint created_at;
        string addDelivery;
        uint price;
    }

    struct Shop{
        string title;
        string description;
        string logo;
        address holder;
        bool status;
    }

    mapping(uint => string[]) public prodImages;
    mapping(address => Shop) public shop;
    mapping(uint => Review[]) public reviews;
    mapping(address => Role) public users;

    constructor(address _shop, string memory _nameTovar){
        address Owner = msg.sender;

        _mint(Owner, 21000000*decim);


        shop[_shop] = Shop(unicode"123", unicode"text","logo.jpg", _shop, true);
        shops.push(Shop(unicode"123", unicode"text", "logo.jpg", _shop, true));
        Catalog.push(Product(0, _nameTovar, unicode"Крутой роутер", 5*decim, _shop, 20, block.timestamp));
    }
    //Создание заявки на покупку
    function createOrder(uint _product, string memory _addDelivery, uint _amount) public{
        require(balanceOf(msg.sender) >= Catalog[_product].tokenPrice, unicode"На вашем аккаунте недостаточно токенов!");
        require(Catalog[_product].amount >= _amount, unicode"У магазина недостаточно товара!");
        transfer(address(this), Catalog[_product].tokenPrice * _amount);
        orders.push(Order(orders.length, _product, _amount, msg.sender, Status.confirmation, block.timestamp, _addDelivery, Catalog[_product].tokenPrice*_amount));
        Catalog[_product].amount -= _amount;
    }

    //Отмена заявки на покупку
    function rejectOrder(uint _number) public {
        require(orders[_number].status == Status.confirmation, unicode"Заявка уже не в статусе 'В подтверждении!', её нельзя отменить!");
        _transfer(address(this), orders[_number].user, orders[_number].price);
        Catalog[orders[_number].product].amount += orders[_number].amount;
        orders[_number].status = Status.rejected;
    }

    //Перевод заявки в доставку
    function deliveryOrder(uint _number) public {
        require(orders[_number].status == Status.confirmation, unicode"Заявка уже не в статусе 'В подтверждении!', её нельзя перевести в доставку!");
        orders[_number].status = Status.delivery;
    }

    //Подтверждение доставки
    function completeOrder(uint _number) public {
        require(orders[_number].status == Status.delivery, unicode"Заявка уже не в статусе 'В доставке', её нельзя подтвердить!");
        orders[_number].status = Status.completed;
        _transfer(address(this), Catalog[orders[_number].product].shop, orders[_number].price);
    }

    //Заявка на магазин
    function requireShop(string memory _title, string memory _description, string memory _logo) public {
        reqShop.push(Shop(_title, _description, _logo, msg.sender, true));
    }

    //Подтверждение/отклонение заявки на магазин
    function applyReqShop(uint _number, bool _answer) public {
        if(_answer){
            shop[reqShop[_number].holder] = reqShop[_number];
            shops.push(reqShop[_number]);
            users[reqShop[_number].holder] = Role.Shop;
            delete reqShop[_number];  
        }else{
            delete reqShop[_number];
        }
    }

    //Отзыв о товаре
    function createReview(uint _product, uint _grade, string memory _description) public {
        reviews[_product].push(Review(_grade, _description, msg.sender));
    }

    //Добавление товара
    function createProduct(string memory _title, string memory _description, uint _tokenPrice, uint _amount, string[] memory _images) public {
        uint id = Catalog.length;
        Catalog.push(Product(id, _title, _description, _tokenPrice*decim, msg.sender, _amount, block.timestamp));
        prodImages[id] = _images;
    }

    //Вывод каталога
    function viewCatalog() public view returns(Product[] memory){
        return Catalog;
    }
    
}
