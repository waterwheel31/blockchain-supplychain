pragma solidity ^0.5.8;
// Define a contract 'Supplychain'
contract SupplyChain {

  // Define 'owner'
  address payable owner;

  // Define a variable called 'upc' for Universal Product Code (UPC)
  uint  upc;

  // Define a variable called 'sku' for Stock Keeping Unit (SKU)
  uint  sku;

  // Define a public mapping 'items' that maps the UPC to an Item.
  mapping (uint => Item) items;

  // Define a public mapping 'itemsHistory' that maps the UPC to an array of TxHash, 
  // that track its journey through the supply chain -- to be sent from DApp.
  mapping (uint => string[]) itemsHistory;
  
  // Define enum 'State' with the following values:
  enum State 
  { 
    Harvested,  // 0
    Processed,  // 1
    Packed,     // 2
    ForSaleAtFarmer, // 3
    SoldAtFarmer,       // 4
    Ordered,          // 5
    ShippingRequested, // 6
    Shipped,    // 7
    AtStore,   // 8
    Purchased   // 9
    }

  State constant defaultState = State.Harvested;

  // Define a struct 'Item' with the following fields:
  struct Item {
    uint    sku;  // Stock Keeping Unit (SKU)
    uint    upc; // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
    address payable ownerID;  // Metamask-Ethereum address of the current owner as the product moves through 8 stages
    address payable originFarmerID; // Metamask-Ethereum address of the Farmer
    string  originFarmName; // Farmer Name
    string  originFarmInformation;  // Farmer Information
    string  originFarmLatitude; // Farm Latitude
    string  originFarmLongitude;  // Farm Longitude
    uint    productID;  // Product ID potentially a combination of upc + sku
    string  productNotes; // Product Notes
    uint    productPrice; // Product Price
    State   itemState;  // Product State as represented in the enum above
    address payable distributorID;  // Metamask-Ethereum address of the Distributor
    address payable retailerID; // Metamask-Ethereum address of the Retailer
    address payable consumerID; // Metamask-Ethereum address of the Consumer
    address payable farmerID; // Metamask-Ethereum address of the Farmer
  }

  // Define 8 events with the same 8 state values and accept 'upc' as input argument
  event Harvested(uint upc);
  event Processed(uint upc);
  event Packed(uint upc);
  event ForSaleAtFarmer(uint upc);
  event SoldAtFarmer(uint upc);
  event Ordered(uint upc);
  event ShippingRequested(uint upc);
  event Shipped(uint upc);
  event Received(uint upc);
  event Purchased(uint upc);

  // Define a modifer that checks to see if msg.sender == owner of the contract
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // Define a modifier that checks the sender is the farmer of the item
  modifier onlyTheFarmer(uint _upc) {
    require(msg.sender == items[_upc].farmerID);
    _;
  }

  // Define a modifier that checks the sender is the distributor of the item
  modifier onlyTheDistributor(uint _upc) {
    require(msg.sender == items[_upc].distributorID);
    _;
  }

  // Define a modifier that checks the sender is the retailer of the item
  modifier onlyTheRetailer(uint _upc) {
    require(msg.sender == items[_upc].retailerID);
    _;
  }

  // Define a modifer that verifies the Caller
  modifier verifyCaller (address _address) {
    require(msg.sender == _address); 
    _;
  }

  // Define a modifier that checks if the paid amount is sufficient to cover the price
  modifier paidEnough(uint _price) { 
    require(msg.value >= _price); 
    _;
  }
  
  // Define a modifier that checks the price and refunds the remaining balance
  modifier checkValue(uint _upc) {
    _;
    uint _price = items[_upc].productPrice;
    uint amountToReturn = msg.value - _price;
    items[_upc].consumerID.transfer(amountToReturn);
  }

  // Define a modifier that checks if an item.state of a upc is Harvested
  modifier harvested(uint _upc) {
    require(items[_upc].itemState == State.Harvested);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Processed
  modifier processed(uint _upc) {
    require(items[_upc].itemState == State.Processed);
    _;
  }
  
  // Define a modifier that checks if an item.state of a upc is Packed
  modifier packed(uint _upc) {
    require(items[_upc].itemState == State.Packed);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is ForSaleAtFarmer
  modifier forSaleAtFarmer(uint _upc) {
    require(items[_upc].itemState == State.ForSaleAtFarmer);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is SoldAtFarmer
  modifier soldAtFarmer(uint _upc) {
    require(items[_upc].itemState == State.SoldAtFarmer);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Ordered
  modifier ordered(uint _upc) {
    require(items[_upc].itemState == State.Ordered);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is ShippingRequested
  modifier shippingRequested(uint _upc) {
    require(items[_upc].itemState == State.ShippingRequested);
    _;
  }
  

  // Define a modifier that checks if an item.state of a upc is Shipped
  modifier shipped(uint _upc) {
    require(items[_upc].itemState == State.Shipped);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Received
  modifier atStore(uint _upc) {
    require(items[_upc].itemState == State.AtStore);
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Purchased
  modifier purchased(uint _upc) {
    require(items[_upc].itemState == State.Purchased);
    _;
  }

  // In the constructor set 'owner' to the address that instantiated the contract
  // and set 'sku' to 1
  // and set 'upc' to 1
  constructor() public payable {
    owner = msg.sender;
    sku = 1;
    upc = 1;
  }

  // Define a function 'kill' if required
  function kill() public {
    if (msg.sender == owner) {
      selfdestruct(owner);
    }
  }

  // Define a function 'harvestItem' that allows a farmer to mark an item 'Harvested'
  function harvestItem(uint _upc, address payable _originFarmerID, 
    string memory _originFarmName, string memory _originFarmInformation, string  memory _originFarmLatitude, string  memory _originFarmLongitude, string memory  _productNotes) public 
  {
    // Add the new item as part of Harvest
    items[_upc] = Item({
      sku: sku,
      upc: _upc,
      ownerID: msg.sender,
      originFarmerID: _originFarmerID,
      originFarmName: _originFarmName,
      originFarmInformation: _originFarmInformation,
      originFarmLatitude: _originFarmLatitude,
      originFarmLongitude: _originFarmLongitude,
      productID: upc + sku, 
      productNotes: _productNotes,
      productPrice: 0,
      itemState: State.Harvested,
      distributorID: address(0),
      retailerID: address(0),
      consumerID: address(0),
      farmerID: msg.sender
    });
    // Increment sku
    sku = sku + 1;
    // Emit the appropriate event
    emit Harvested(_upc);
  }

  // Define a function 'processtItem' that allows a farmer to mark an item 'Processed'
  function processItem(uint _upc) public 
  // Call modifier to check if upc has passed previous supply chain stage
    harvested(_upc)
  // Call modifier to verify caller of this function
    onlyOwner
  {
    // Update the appropriate fields
    items[_upc].itemState = State.Processed;
    // Emit the appropriate event
    emit Processed(_upc);
  }

  // Define a function 'packItem' that allows a farmer to mark an item 'Packed'
  function packItem(uint _upc) public 
  // Call modifier to check if upc has passed previous supply chain stage
    processed(_upc)
  // Call modifier to verify caller of this function
    onlyOwner()
  {
    // Update the appropriate fields
    items[_upc].itemState = State.Packed;
    // Emit the appropriate event
    emit Packed(_upc);
  }

  // Define a function 'sellItem' that allows a farmer to mark an item 'ForSale'
  function sellItem(uint _upc, uint _price) public 
  // Call modifier to check if upc has passed previous supply chain stage
    packed(_upc)
  // Call modifier to verify caller of this function
    onlyOwner()
  {
    // Update the appropriate fields
    items[_upc].itemState = State.ForSaleAtFarmer;
    items[_upc].productPrice = _price;
    // Emit the appropriate event
    emit ForSaleAtFarmer(_upc);
  }

  // Define a function 'buyItem' that allows the disributor to mark an item 'Sold'
  // Use the above defined modifiers to check if the item is available for sale, if the buyer has paid enough, 
  // and any excess ether sent is refunded back to the buyer
  function buyItem(uint _upc) public payable 
    // Call modifier to check if upc has passed previous supply chain stage
    forSaleAtFarmer(_upc)
    // Call modifer to check if buyer has paid enough
    paidEnough(items[_upc].productPrice)
    // Call modifer to send any excess ether back to buyer
    checkValue(_upc)
    {
      // Transfer money to farmer
      items[_upc].farmerID.transfer(items[_upc].productPrice);
      // Update the appropriate fields - ownerID, distributorID, itemState
      items[_upc].ownerID = msg.sender; 
      items[_upc].distributorID = msg.sender;
      items[_upc].itemState = State.SoldAtFarmer;
   
      // emit the appropriate event
      emit SoldAtFarmer(_upc);
  }

  // Define a function "orderItem" that allows the retailer to mark an item 'ordered'
  // 

  function orderItem(uint _upc) public payable
    // Call modifier to check if ups has passed previous supply chain stage
    soldAtFarmer(_upc)
    // Call modifer to check if buyer has paid enough
    paidEnough(items[_upc].productPrice)
    // Call modifer to send any excess ether back to buyer
    checkValue(_upc)
    {
      // Transfer money to distributor
      items[_upc].distributorID.transfer(items[_upc].productPrice);
      // Update the appropriate fields - ownerID, distributorID, itemState
      items[_upc].ownerID = msg.sender; 
      items[_upc].retailerID = msg.sender;
      items[_upc].itemState = State.Ordered;
    }


  // Define a function 'requestShipping' that allows the distributor to request shipping to the farmer
  // Use the above modifers to check if the item is sold
  function requestShipping(uint _upc) public 
    // Call modifier to check if upc has passed previous supply chain stage
    ordered(_upc)
    // Call modifier to verify caller of this function
    onlyTheDistributor(_upc)
    {
    // Update the appropriate fields
      items[_upc].itemState = State.ShippingRequested;
    // Emit the appropriate event
      emit ShippingRequested(_upc); 
    
  }

  // Define a function 'shipItem' that allows the farmer to ship 
  // Use the above modifers to check if the item is sold
  function shipItem(uint _upc) public 
    // Call modifier to check if upc has passed previous supply chain stage
    shippingRequested(_upc)
    // Call modifier to verify caller of this function
    onlyTheFarmer(_upc)
    {
    // Update the appropriate fields
      items[_upc].itemState = State.Shipped;
    // Emit the appropriate event
      emit Shipped(_upc);
  }

  // Define a function 'receiveItem' that allows the retailer to mark an item 'Received'
  // Use the above modifiers to check if the item is shipped
  function receiveItem(uint _upc) public 
    // Call modifier to check if upc has passed previous supply chain stage
    shippingRequested(_upc)
    // Access Control List enforced by calling Smart Contract / DApp
    onlyTheRetailer(_upc)
    {
    // Update the appropriate fields - ownerID, retailerID, itemState
      items[_upc].ownerID = msg.sender; 
      items[_upc].retailerID = msg.sender;
      items[_upc].itemState = State.Shipped;
    // Emit the appropriate event
      emit Received(_upc);
    
  }

  // Define a function 'purchaseItem' that allows the consumer to mark an item 'Purchased'
  // Use the above modifiers to check if the item is received
  function purchaseItem(uint _upc) public payable
    // Call modifier to check if upc has passed previous supply chain stage
    atStore(_upc)
    // Call modifer to check if buyer has paid enough
    paidEnough(items[_upc].productPrice)
    // Call modifer to send any excess ether back to buyer
    checkValue(_upc)
    // Access Control List enforced by calling Smart Contract / DApp
    {
    // Transfer money to retailer
      items[_upc].retailerID.transfer(items[_upc].productPrice);
    // Update the appropriate fields - ownerID, consumerID, itemState
      items[_upc].ownerID = msg.sender; 
      items[_upc].consumerID = msg.sender;
      items[_upc].itemState = State.Purchased;
    // Emit the appropriate event
      emit Purchased(_upc);
    
  }

  // Define a function 'fetchItemBuffer' that fetches the data
  function fetchItemBufferOne(uint _upc) public view returns 
    (
      uint    itemSKU,
      uint    itemUPC,
      address ownerID,
      address originFarmerID,
      string  memory originFarmName,
      string  memory originFarmInformation,
      string  memory originFarmLatitude,
      string  memory originFarmLongitude,
      State itemState
    ) 
    {

    // Assign values to the 8 parameters
    itemSKU = items[_upc].sku;
    itemUPC = items[_upc].upc;
    ownerID = items[_upc].ownerID;
    originFarmerID = items[_upc].originFarmerID;
    originFarmName = items[_upc].originFarmName;
    originFarmInformation = items[_upc].originFarmInformation;
    originFarmLatitude = items[_upc].originFarmLatitude;
    originFarmLongitude = items[_upc].originFarmLongitude;
    itemState = items[_upc].itemState;

    return (
      itemSKU,
      itemUPC,
      ownerID,
      originFarmerID,
      originFarmName,
      originFarmInformation,
      originFarmLatitude,
      originFarmLongitude,
      itemState
      );
    }

}
