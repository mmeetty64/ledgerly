//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Ledgerly is ERC20("LedgerlyToken", "LED"){
    function decimals() public view virtual override returns (uint8) {
    return 4;
    }

    address Owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint decim = 10**decimals();
    uint Time_start = block.timestamp;
    uint tokenPrice = 0.00034 ether;
    enum Role{Guest, User, Shop, Admin, Owner}
    enum Status{confirmation, delivery, completed, rejected}
    enum Paying{ethereum, token}
    Product[] public Catalog;
    Order[] public orders;
    Shop[] public shops;
    Shop[] public reqShop;
    BanList[] public listBan;

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
        bool status;
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
    }

    struct BanList{
        uint id;
        address user;
        string description;
    }

    mapping(uint => string[]) public prodImages;
    mapping(address => Shop) public shop;
    mapping(uint => Review[]) public reviews;
    mapping(address => Role) public users;
    mapping(address => BanList) public banList;

    constructor(){
        address _shop = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        users[0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266] = Role.Owner;

        users[0x70997970C51812dc3A010C7d01b50e0d17dc79C8] = Role.Shop;

        users[0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC] = Role.User;
        users[0x90F79bf6EB2c4f870365E785982E1f101E93b906] = Role.User;
        users[0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65] = Role.User;


        _mint(Owner, 21000000*decim);


        shop[_shop] = Shop(unicode"123", unicode"text","logo.jpg", _shop);
        shops.push(Shop(unicode"123", unicode"text", "logo.jpg", _shop));
        Catalog.push(Product(0, unicode"Роутер", unicode"Крутой роутер", 5*decim, _shop, 20, block.timestamp, true));

        prodImages[0] = ["price.jpg"];

        Catalog.push(Product(1, unicode"Наушники", unicode"Крутые наушники", 10*decim, _shop, 20, block.timestamp, true));

        prodImages[1] = ["beeheadphones.jpg"];

        Catalog.push(Product(2, unicode"Поко фэ3", unicode"Лучший в мире телефон", 5*decim, _shop, 20, block.timestamp, true));

        prodImages[2] = ["betterphone.jpg"];

        Catalog.push(Product(3, unicode"Эйподсы", unicode"Очень дорого, не советую", 5*decim, _shop, 20, block.timestamp, true));

        prodImages[3] = ["headphones.jpg"];

        Catalog.push(Product(4, unicode"Айфон", unicode"Переоцененная шаблонная штука", 5*decim, _shop, 20, block.timestamp, true));

        prodImages[4] = ["phone.jpg"];

        Catalog.push(Product(5, unicode"Танк", unicode"Крутой, можно гвозди забивать!", 5*decim, _shop, 20, block.timestamp, true));

        prodImages[5] = ["thebestphone.jpg"];
    }

    //USER (ПОЛЬЗОВАТЕЛЬ)

    //Создание заявки на покупку
    function createOrder(uint _product, string memory _addDelivery, uint _amount) public onlyUser{
        require(balanceOf(msg.sender) >= Catalog[_product].tokenPrice, unicode"На вашем аккаунте недостаточно токенов!");
        require(Catalog[_product].amount >= _amount, unicode"У магазина недостаточно товара!");
        transfer(address(this), Catalog[_product].tokenPrice * _amount);
        orders.push(Order(orders.length, _product, _amount, msg.sender, Status.confirmation, block.timestamp, _addDelivery, Catalog[_product].tokenPrice*_amount));
        Catalog[_product].amount -= _amount;
    }

    //Отмена заявки на покупку
    function rejectOrder(uint _number) public allWorkRole{
        require(orders[_number].status == Status.confirmation, unicode"Заявка уже не в статусе 'В подтверждении!', её нельзя отменить!");
        _transfer(address(this), orders[_number].user, orders[_number].price);
        Catalog[orders[_number].product].amount += orders[_number].amount;
        orders[_number].status = Status.rejected;
    }

    //Подтверждение доставки
    function completeOrder(uint _number) public onlyUser{
        require(orders[_number].status == Status.delivery, unicode"Заявка уже не в статусе 'В доставке', её нельзя подтвердить!");
        orders[_number].status = Status.completed;
        _transfer(address(this), Catalog[orders[_number].product].shop, orders[_number].price);
    }

    //Заявка на магазин
    function requireShop(string memory _title, string memory _description, string memory _logo) public onlyUser{
        reqShop.push(Shop(_title, _description, _logo, msg.sender));
    }

    //Отзыв о товаре
    function createReview(uint _product, uint _grade, string memory _description) public onlyUser{
        reviews[_product].push(Review(_grade, _description, msg.sender));
    }
    
    //Покупка токенов
    function buyTokens(uint _amount) external payable allWorkRole{
        require(msg.value >= _amount * tokenPrice, unicode"Вы передали недостаточно ETH");
        require(_amount*decim <= balanceOf(Owner), unicode"Недостаточно токенов в системе");
        _transfer(Owner, msg.sender, _amount * decim);
    }

    //SHOP (МАГАЗИНЫ):

    //Перевод заявки в доставку
    function deliveryOrder(uint _number) public onlyShop{
        require(orders[_number].status == Status.confirmation, unicode"Заявка уже не в статусе 'В подтверждении!', её нельзя перевести в доставку!");
        orders[_number].status = Status.delivery;
    }

    //Добавление товара
    function createProduct(string memory _title, string memory _description, uint _tokenPrice, uint _amount, string[] memory _images) public onlyShop{
        uint id = Catalog.length;
        Catalog.push(Product(id, _title, _description, _tokenPrice*decim, msg.sender, _amount, block.timestamp, true));
        prodImages[id] = _images;
    }

    //Заморозка товара
    function frozeProduct(uint _id) public onlyShop{
        Catalog[_id].status = false;
    }

    //Разморозка товара
    function unfrozeProduct(uint _id) public onlyShop{
        Catalog[_id].status = true;
    }

    //ADMIN (АДМИН):

    //Подтверждение/отклонение заявки на магазин
    function applyReqShop(uint _number, bool _answer) public onlyAdmin{
        if(_answer){
            shop[reqShop[_number].holder] = reqShop[_number];
            shops.push(reqShop[_number]);
            users[reqShop[_number].holder] = Role.Shop;
            delete reqShop[_number];  
        }else{
            delete reqShop[_number];
        }
    }

    //Бан пользователя
    function blockUser(address _user, string memory _description) public onlyAdmin{
        listBan.push(BanList(listBan.length, _user, _description));
        banList[_user] = BanList(listBan.length, _user, _description);
    }

    //Разбан пользователя
    function unbanUser(uint _id) public onlyAdmin{
        delete banList[listBan[_id].user];
        delete listBan[_id];
    }

    //Добавление товара от админа
    function createProductAdmin(string memory _title, string memory _description, uint _tokenPrice, uint _amount, string[] memory _images, address _shop) public onlyAdmin{
        uint id = Catalog.length;
        Catalog.push(Product(id, _title, _description, _tokenPrice*decim, _shop, _amount, block.timestamp, true));
        prodImages[id] = _images;
    }

    //ПРОВЕРКИ:

    //Проверка на бан аккаунта
    modifier onlyNotBan{
        require(banList[msg.sender].user == address(0), unicode"Ваш аккаунт заморожен!");
        _;
    }

    //Проверка на админа
    modifier onlyAdmin{
        require(users[msg.sender] == Role.Admin, unicode"Вы не администратор!");
        _;
    }

    //Проверка на владельца системы
    modifier onlyOwner{
        require(users[msg.sender] == Role.Owner, unicode"Вы не владелец системы!");
        _;
    }

    //Проверка на магазин
    modifier onlyShop{
        require(users[msg.sender] == Role.Shop || users[msg.sender] == Role.Admin, unicode"Вы не магазин!");
        _;
    }

    modifier allWorkRole{
        require(users[msg.sender] == Role.Admin || users[msg.sender] == Role.Shop || users[msg.sender] == Role.User, unicode"Вы не можете использовать эту функцию системы!");
        _;
    }

    //Проверка на юзера
    modifier onlyUser{
        require(users[msg.sender] == Role.User || users[msg.sender] == Role.Admin, unicode"Вы не пользователь системы!");
        _;
    }

    //VIEW FUNCTIONS:

    //Вывод каталога
    function viewCatalog() public view returns(Product[] memory){
        return Catalog;
    }

    function viewProduct(uint _id) public view  returns(Product memory){
        return Catalog[_id];
    }

    function viewProdImg(uint _idProd) public view returns(string[] memory){
        return prodImages[_idProd];
    }

    function viewShopData(address _shop) public view returns(Shop memory){
        return  shop[_shop];
    }

    function viewProdReview(uint _prodId) public view returns(Review[] memory){
        return  reviews[_prodId];
    }

    function viewTokenPrice() public view returns(uint){
        return tokenPrice;
    }
    function viewRole(address _user) public  view returns(Role){
        return users[_user];
    }
    function viewOrders() public  view returns(Order[] memory){
        return orders;
    }
    
}
