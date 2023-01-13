// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error ChatSignalingMedium__CallerIsNotAParticipant();
error ChatSignalingMedium__RecipientIsNotAParticipant();
error ChatSignalingMedium__NameAlreadyRegistered();
error ChatSignalingMedium__CannotConnectToItself();
error ChatSignalingMedium__NameTooLong();

contract ChatSignalingMedium {
    struct Participant {
        address owner;
        string name;
        bytes32 nameHash;
        bytes publicEncryptionKey;
        //signaling data
        //should be encrypted because all of blockchain data is public
        mapping(bytes32 => bytes) offersFrom;
        mapping(bytes32 => bytes) answersFrom;
        //
        uint256 notTrash;
    }

    event OfferMade(address indexed to, address from);
    event AnswerMade(address indexed to, address from);

    mapping(bytes32 => Participant) private participants;
    mapping(address => bytes32) private addressToNameHash;

    constructor() {
        register("", "key");
    }

    //may be we need to forbid re-registering
    //name is supposed to be ascii string
    function register(
        string memory name,
        bytes memory publicEncryptionKey
    ) public {
        if (bytes(name).length > 30) {
            revert ChatSignalingMedium__NameTooLong();
        }

        bytes32 key = sha256(abi.encodePacked(name));

        if (
            isParticipantNameHash(key) &&
            (getParticipantAddressByNameHash(key) != msg.sender)
        ) {
            revert ChatSignalingMedium__NameAlreadyRegistered();
        }

        Participant storage participant = participants[key];
        participant.owner = msg.sender;
        participant.name = name;
        participant.nameHash = key;
        participant.notTrash = 1;
        participant.publicEncryptionKey = publicEncryptionKey;

        //solidity can't do it! with nested mapping
        /*participants[key] = Participant({
            owner: msg.sender,
            name: name,
            nameHash: key,
            notTrash: 1
        });*/
        addressToNameHash[msg.sender] = key;
    }

    function isParticipantAddress(address addr) public view returns (bool) {
        return addressToNameHash[addr] != 0;
    }

    function isParticipantNameHash(
        bytes32 nameHash
    ) public view returns (bool) {
        return participants[nameHash].notTrash == 1;
    }

    function initiateConnection(
        bytes32 to,
        bytes calldata requestToken
    ) public fromParticipant {
        bytes32 senderNameHash = addressToNameHash[msg.sender];
        if (to == senderNameHash)
            revert ChatSignalingMedium__CannotConnectToItself();
        if (!isParticipantNameHash(to))
            revert ChatSignalingMedium__RecipientIsNotAParticipant();

        participants[to].offersFrom[senderNameHash] = requestToken;

        emit OfferMade(participants[to].owner, msg.sender);
    }

    function acceptConnection(
        bytes32 from,
        bytes calldata responseToken
    ) public fromParticipant {
        bytes32 senderNameHash = addressToNameHash[msg.sender];
        if (from == senderNameHash)
            revert ChatSignalingMedium__CannotConnectToItself();
        if (!isParticipantNameHash(from))
            revert ChatSignalingMedium__RecipientIsNotAParticipant();

        participants[from].answersFrom[senderNameHash] = responseToken;

        emit AnswerMade(participants[from].owner, msg.sender);
    }

    function getParticipantNameHashByAddress(
        address addr
    ) public view returns (bytes32) {
        return addressToNameHash[addr];
    }

    function getParticipantNameByAddress(
        address addr
    ) public view returns (string memory) {
        return participants[addressToNameHash[addr]].name;
    }

    function getParticipantAddressByNameHash(
        bytes32 nameHash
    ) public view returns (address) {
        return participants[nameHash].owner;
    }

    function getEncryptionKeyByAddress(
        address addr
    ) public view returns (bytes memory) {
        return participants[addressToNameHash[addr]].publicEncryptionKey;
    }

    function getConnectionRequestToken(
        bytes32 to,
        bytes32 from
    ) public view returns (bytes memory) {
        return participants[to].offersFrom[from];
    }

    function getConnectionRequestTokenByAddresses(
        address to,
        address from
    ) public view returns (bytes memory) {
        return
            participants[addressToNameHash[to]].offersFrom[
                addressToNameHash[from]
            ];
    }

    function getConnectionRequestAnswerToken(
        bytes32 to,
        bytes32 from
    ) public view returns (bytes memory) {
        return participants[to].answersFrom[from];
    }

    function getConnectionRequestAnswerTokenByAddresses(
        address to,
        address from
    ) public view returns (bytes memory) {
        return
            participants[addressToNameHash[to]].answersFrom[
                addressToNameHash[from]
            ];
    }

    modifier fromParticipant() {
        if (uint256(addressToNameHash[msg.sender]) == 0)
            revert ChatSignalingMedium__CallerIsNotAParticipant();
        _;
    }
}
