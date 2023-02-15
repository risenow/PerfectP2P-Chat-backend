// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error ChatSignalingMedium__CallerIsNotAParticipant();
error ChatSignalingMedium__RecipientIsNotAParticipant();
error ChatSignalingMedium__NameAlreadyRegistered();
error ChatSignalingMedium__CannotConnectToItself();
error ChatSignalingMedium__NameTooLong();
error ChatSignalingMedium__EncKeyTooLong();

contract ChatSignalingMedium {
    struct AnsweringMachineMsg {
        address sender;
        bytes msgContent; // subject to chat
        uint256 timestamp;
        bool answered;
    }
    struct ConnectionRequest {
        uint256 leftMsgIdx;
        bytes requestToken;
    }

    struct Participant {
        address owner;
        string name;
        bytes32 nameHash;
        bytes publicEncryptionKey;
        //signaling data
        //should be encrypted because all of blockchain data is public
        mapping(bytes32 => ConnectionRequest) offersFrom;
        mapping(bytes32 => bytes) answersFrom;
        //left msgs also should be encrypted
        AnsweringMachineMsg[] leftMsgs;
        //
        uint256 notTrash;
    }

    event OfferMade(address indexed to, address from, uint256 leftMsgIdx);
    event AnswerMade(address indexed to, address from);

    mapping(bytes32 => Participant) private participants;
    mapping(address => bytes32) private addressToNameHash;

    constructor() {
        register("", "key");
    }

    //may be we need to forbid re-registering
    //name is supposed to be ascii string
    /**
     *
     * @param name plain participant name
     * @param publicEncryptionKey public encryption key of the participant
     */
    function register(
        string memory name,
        bytes memory publicEncryptionKey
    ) public {
        if (bytes(name).length > 30) {
            revert ChatSignalingMedium__NameTooLong();
        }
        if (publicEncryptionKey.length > 256) {
            revert ChatSignalingMedium__EncKeyTooLong();
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

        //solidity can't do it with nested mapping
        /*participants[key] = Participant({
            owner: msg.sender,
            name: name,
            nameHash: key,
            notTrash: 1
        });*/
        addressToNameHash[msg.sender] = key;
    }

    /**
     *
     * @param addr address
     * returns boolean which spicifies whether there is registered participant whose address is addr
     */
    function isParticipantAddress(address addr) public view returns (bool) {
        return addressToNameHash[addr] != 0;
    }

    /**
     *
     * @param nameHash name hash
     * returns boolean which spicifies whether there is registered participant whose name hash is nameHash
     */
    function isParticipantNameHash(
        bytes32 nameHash
    ) public view returns (bool) {
        return participants[nameHash].notTrash == 1;
    }

    /**
     *
     * @param to Adressant name hash
     * @param requestToken WebRTC offer
     * @param subjectMsg msg with specified subject of the proposed chat(then put to answering machine)
     */
    function initiateConnection(
        bytes32 to,
        bytes calldata requestToken,
        bytes calldata subjectMsg
    ) public fromParticipant {
        bytes32 senderNameHash = addressToNameHash[msg.sender];
        if (to == senderNameHash)
            revert ChatSignalingMedium__CannotConnectToItself();
        if (!isParticipantNameHash(to))
            revert ChatSignalingMedium__RecipientIsNotAParticipant();

        uint256 leftMsgIdx = participants[to].leftMsgs.length;
        participants[to].offersFrom[senderNameHash] = ConnectionRequest(
            leftMsgIdx,
            requestToken
        );
        participants[to].leftMsgs.push(
            AnsweringMachineMsg(msg.sender, subjectMsg, block.timestamp, false)
        );

        emit OfferMade(participants[to].owner, msg.sender, leftMsgIdx);
    }

    /**
     *
     * @param from function for a callee participant to accept offered connection
     * which basically means posting an answer to the connection initiator
     * returns number of msgs that recipient holds
     */
    function acceptConnection(
        bytes32 from,
        bytes calldata responseToken
    ) public fromParticipant {
        bytes32 senderNameHash = addressToNameHash[msg.sender]; //tx sender
        if (from == senderNameHash)
            revert ChatSignalingMedium__CannotConnectToItself();
        if (!isParticipantNameHash(from))
            revert ChatSignalingMedium__RecipientIsNotAParticipant();

        //mb memory variables aka references?
        participants[senderNameHash]
            .leftMsgs[participants[senderNameHash].offersFrom[from].leftMsgIdx]
            .answered = true;

        participants[from].answersFrom[senderNameHash] = responseToken;

        emit AnswerMade(participants[from].owner, msg.sender);
    }

    /**
     *
     * @param to address of the msg recipient
     * returns number of msgs that recipient holds
     */
    function getParticipantLeftMsgsCount(
        address to
    ) public view returns (uint256) {
        return participants[addressToNameHash[to]].leftMsgs.length;
    }

    /**
     *
     * @param to address of the msg recipient
     * @param msgIdx index of the msg
     * returns msg content(hopefully encrypted)
     */
    function getParticipantLeftMsg(
        address to,
        uint256 msgIdx
    ) public view returns (bytes memory) {
        return participants[addressToNameHash[to]].leftMsgs[msgIdx].msgContent;
    }

    /**
     *
     * @param to address of the msg recipient
     * @param msgIdx index of the msg
     * returns if corresponding connection was answered
     */
    function isParticipantLeftMsgAnswered(
        address to,
        uint256 msgIdx
    ) public view returns (bool) {
        return participants[addressToNameHash[to]].leftMsgs[msgIdx].answered;
    }

    /**
     *
     * @param to address of the msg recipient
     * @param msgIdx index of the msg
     * returns msg timestamp
     */
    function getParticipantLeftMsgSenderAddress(
        address to,
        uint256 msgIdx
    ) public view returns (address) {
        return participants[addressToNameHash[to]].leftMsgs[msgIdx].sender;
    }

    /**
     *
     * @param to address of the msg recipient
     * @param msgIdx index of the msg
     * returns msg timestamp
     */
    function getParticipantLeftMsgTimestamp(
        address to,
        uint256 msgIdx
    ) public view returns (uint256) {
        return participants[addressToNameHash[to]].leftMsgs[msgIdx].timestamp;
    }

    /**
     *
     * @param to name hash of the recipient
     * @param from name hash of the connection initiator
     * returns tuple of connection request token and subject msg index
     */
    function getConnectionRequestTokenWithSubject(
        bytes32 to,
        bytes32 from
    ) public view returns (bytes memory requestToken, uint256 subjectMsgIdx) {
        ConnectionRequest storage req = participants[to].offersFrom[from];

        return (req.requestToken, req.leftMsgIdx);
    }

    /**
     *
     * @param addr address of the participant
     * returns hash of the participant name
     */
    function getParticipantNameHashByAddress(
        address addr
    ) public view returns (bytes32) {
        return addressToNameHash[addr];
    }

    /**
     *
     * @param addr address of the participant
     * returns plain string nickname of the participant
     */
    function getParticipantNameByAddress(
        address addr
    ) public view returns (string memory) {
        return participants[addressToNameHash[addr]].name;
    }

    /**
     *
     * @param nameHash has of the participant name
     * returns address of the corresponding participant
     */
    function getParticipantAddressByNameHash(
        bytes32 nameHash
    ) public view returns (address) {
        return participants[nameHash].owner;
    }

    /**
     *
     * @param addr address of the participant
     * returns key for the public key encryption scheme
     */
    function getEncryptionKeyByAddress(
        address addr
    ) public view returns (bytes memory) {
        return participants[addressToNameHash[addr]].publicEncryptionKey;
    }

    /**
     *
     * @param to name hash of connection recipient
     * @param from name hash of connection initiator
     * returns connection request token(hopefully encrypted)
     */
    function getConnectionRequestToken(
        bytes32 to,
        bytes32 from
    ) public view returns (bytes memory) {
        return participants[to].offersFrom[from].requestToken;
    }

    /**
     *
     * @param to adress of connection recipient
     * @param from address of connection initiator
     * returns connection request token(hopefully encrypted)
     */
    function getConnectionRequestTokenByAddresses(
        address to,
        address from
    ) public view returns (bytes memory) {
        return
            participants[addressToNameHash[to]]
                .offersFrom[addressToNameHash[from]]
                .requestToken;
    }

    /**
     *
     * @param to name hash of connection recipient
     * @param from name hash of connection initiator
     * returns connection request answer token(hopefully encrypted)
     */
    function getConnectionRequestAnswerToken(
        bytes32 to,
        bytes32 from
    ) public view returns (bytes memory) {
        return participants[to].answersFrom[from];
    }

    /**
     *
     * @param to address of connection recipient
     * @param from address of connection initiator
     * returns connection request answer token(hopefully encrypted)
     */
    function getConnectionRequestAnswerTokenByAddresses(
        address to,
        address from
    ) public view returns (bytes memory) {
        return
            participants[addressToNameHash[to]].answersFrom[
                addressToNameHash[from]
            ];
    }

    /** ensures caller is registered in the contract */
    modifier fromParticipant() {
        if (uint256(addressToNameHash[msg.sender]) == 0)
            revert ChatSignalingMedium__CallerIsNotAParticipant();
        _;
    }
}
