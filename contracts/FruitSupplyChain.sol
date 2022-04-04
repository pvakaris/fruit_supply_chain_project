// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FruitSupplyChain {
    uint32 public shipment_id = 0;   // Product ID
    uint32 public participant_id = 0;   // Participant ID
    uint32 public owner_id = 0;   // Ownership ID

    struct fruitBatch {
        string name;
        uint32 gatheringTimeStamp;
        string gatheringLocation;
        uint32 weightInGrams;
        uint32 cost;
    }

    struct fruitShipment {
        uint32 id;
        mapping(uint32 => fruitBatch) fruits;
        uint32 weightInGrams;
        address shipmentOwner;
        uint32 cost;
        uint32 assembleTimeStamp;
    }

    mapping(uint32 => fruitShipment) public fruitShipments;

    struct participant {
        string name;
        string participantType;
        address participantAddress;
    }
    mapping(uint32 => participant) public participants;

    struct ownership {
        uint32 shipmentId;
        uint32 ownerId;
        uint32 transactionTimeStamp;
        address productOwner;
    }

    mapping(uint32 => ownership) public ownerships; // ownerships by ownership ID (owner_id)
    mapping(uint32 => uint32[]) public shipmentTrack;  // Track movement of a shipment

    event TransferOwnership(uint32 productId);

    function addParticipant(string memory _name, address _participantAddress, string memory _participantType) public returns (uint32){
        uint32 userId = participant_id++;
        participants[userId].name = _name;
        participants[userId].participantAddress = _participantAddress;
        participants[userId].participantType = _participantType;

        return userId;
    }

    function getParticipant(uint32 _participant_id) public view returns (string memory,address,string memory) {
        return (participants[_participant_id].name,
        participants[_participant_id].participantAddress,
        participants[_participant_id].participantType);
    }

    function createShipment(uint32 _shipmentOwnerId) public returns (uint32) {
        // keccak256 ---> hashing function (ine of the most popular)
        // Using blockchain, you cannot compare two strings, you can only compare their hashes
        if(keccak256(abi.encodePacked(participants[_shipmentOwnerId].participantType)) == keccak256("Farmer")) {
            uint32 id = shipment_id++;

            fruitShipments[id].id = id;
            fruitShipments[id].weightInGrams = 0;
            fruitShipments[id].cost = 0;
            fruitShipments[id].shipmentOwner = participants[_shipmentOwnerId].participantAddress;
            fruitShipments[id].assembleTimeStamp = uint32(block.timestamp);

            return id;
        }

        return 0;
    }

    // modifiers are intended to be added to the definition of a function
    // always end with _;
    modifier onlyOwner(uint32 _shipmentId) {
        require(msg.sender == fruitShipments[_shipmentId].shipmentOwner,"");
        _;
    }

    function getShipment(uint32 _shipmentId) public view returns (uint32,uint32,address,uint32){
        return (fruitShipments[_shipmentId].weightInGrams,
        fruitShipments[_shipmentId].cost,
        fruitShipments[_shipmentId].shipmentOwner,
        fruitShipments[_shipmentId].assembleTimeStamp);
    }

    // this function can only run if the modifier onlyOwner is true
    function newOwner(uint32 _user1Id,uint32 _user2Id, uint32 _shipmentId) onlyOwner(_shipmentId) public returns (bool) {
        participant memory p1 = participants[_user1Id];
        participant memory p2 = participants[_user2Id];
        uint32 ownership_id = owner_id++;

        if(keccak256(abi.encodePacked(p1.participantType)) == keccak256("Farmer")
            && keccak256(abi.encodePacked(p2.participantType))==keccak256("Distributor")){
            ownerships[ownership_id].shipmentId = _shipmentId;
            ownerships[ownership_id].productOwner = p2.participantAddress;
            ownerships[ownership_id].ownerId = _user2Id;
            ownerships[ownership_id].transactionTimeStamp = uint32(block.timestamp);
            fruitShipments[_shipmentId].shipmentOwner = p2.participantAddress;
            // push ---> add to the end
            shipmentTrack[_shipmentId].push(ownership_id);
            emit TransferOwnership(_shipmentId);

            return (true);
        }
        else if(keccak256(abi.encodePacked(p1.participantType)) == keccak256("Distributor") && keccak256(abi.encodePacked(p2.participantType))==keccak256("Distributor")){
            ownerships[ownership_id].shipmentId = _shipmentId;
            ownerships[ownership_id].productOwner = p2.participantAddress;
            ownerships[ownership_id].ownerId = _user2Id;
            ownerships[ownership_id].transactionTimeStamp = uint32(block.timestamp);
            fruitShipments[_shipmentId].shipmentOwner = p2.participantAddress;
            shipmentTrack[_shipmentId].push(ownership_id);
            emit TransferOwnership(_shipmentId);

            return (true);
        }
        else if(keccak256(abi.encodePacked(p1.participantType)) == keccak256("Distributor") && keccak256(abi.encodePacked(p2.participantType))==keccak256("Consumer")){
            ownerships[ownership_id].shipmentId = _shipmentId;
            ownerships[ownership_id].productOwner = p2.participantAddress;
            ownerships[ownership_id].ownerId = _user2Id;
            ownerships[ownership_id].transactionTimeStamp = uint32(block.timestamp);
            fruitShipments[_shipmentId].shipmentOwner = p2.participantAddress;
            shipmentTrack[_shipmentId].push(ownership_id);
            emit TransferOwnership(_shipmentId);

            return (true);
        }

        return (false);
    }

    function getProvenance(uint32 _shipmentId) external view returns (uint32[] memory) {

        return shipmentTrack[_shipmentId];
    }

    function getOwnership(uint32 _regId)  public view returns (uint32,uint32,address,uint32) {

        ownership memory instance = ownerships[_regId];

        return (instance.shipmentId, instance.ownerId, instance.productOwner, instance.transactionTimeStamp);
    }

    function authenticateParticipant(uint32 _uid,
        string memory _participantName,
        string memory _participantType) public view returns (bool){
        if(keccak256(abi.encodePacked(participants[_uid].participantType)) == keccak256(abi.encodePacked(_participantType))) {
            if(keccak256(abi.encodePacked(participants[_uid].name)) == keccak256(abi.encodePacked(_participantName))) {
                return(true);
            }
        }

        return (false);
    }
}