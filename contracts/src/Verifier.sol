// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import "./IVerifier.sol";
import "./libraries/Bytes.sol";
import "./libraries/Challenge.sol";
import "./libraries/MerkleTree.sol";

/**
 * @title Verifier contract
 * @author Seiya Kobayashi
 */
contract Verifier is IVerifier, Ownable {
    /*
        state variables
    */

    // difficulty (number of digits in base 16) of challenge
    uint8 private difficulty;

    // model details
    Model private model;

    // array of commitment IDs
    Hash[] private commitments;
    // mapping of prover address to array of commitment IDs
    mapping(address => Hash[]) private proverAddressToCommitments;
    // mapping of commitment ID of commitment details
    mapping(Hash => Commitment) private commitmentIdToCommitment;

    /*
        events
    */

    // event to be emitted when a model is registered
    event ModelRegistered(Hash indexed contentId, address indexed ownerAddress);
    // event to be emitted when a model is updated
    event ModelUpdated(
        Hash indexed contentId,
        address indexed ownerAddress,
        string name,
        string description
    );
    // event to be emitted when a model is disabled
    event ModelDisabled(Hash indexed contentId, address indexed ownerAddress);

    // event to be emitted when a commitment is added
    event Committed(
        Hash indexed commitmentId,
        address indexed proverAddress,
        Hash _challenge
    );
    // event to be emitted when challenge of a commitment is updated
    event ChallengeUpdated(
        Hash indexed commitmentId,
        address indexed proverAddress,
        Hash _challenge
    );
    // event to be emitted when a commitment is revealed
    event CommitmentRevealed(
        Hash indexed commitmentId,
        address indexed proverAddress
    );

    /*
        modifiers
    */

    modifier isValidDifficulty(uint8 _difficulty) {
        require(_difficulty != 0, "difficulty cannot be 0");
        _;
    }

    modifier validateModelParameters(
        string calldata _modelName,
        string calldata _modelDescription
    ) {
        require(bytes(_modelName).length != 0, "empty modelName");
        require(bytes(_modelDescription).length != 0, "empty modelDescription");
        _;
    }

    modifier validateOffsetParameter(uint32 _offset, uint _length) {
        if (_length > 0) {
            require(
                _offset < _length,
                "offset must be < length of list of items"
            );
        } else {
            require(_offset == 0, "offset must be 0 when no items exist");
        }
        _;
    }

    modifier validateLimitParameter(uint32 _limit) {
        require(_limit > 0 && _limit <= 30, "limit must be > 0 and <= 30");
        _;
    }

    modifier isModelOwner(address _senderAddress) {
        require(
            model.ownerAddress == _senderAddress,
            "only model owner can execute"
        );
        _;
    }

    modifier checkIfCommitmentExists(Hash _commitmentId) {
        require(
            Hash.unwrap(commitmentIdToCommitment[_commitmentId].id) != "",
            "commitment not found"
        );
        _;
    }

    modifier isValidProver(address _proverAddress) {
        require(_proverAddress == msg.sender, "invalid prover");
        _;
    }

    /*
        constructor
    */

    constructor(uint8 _difficulty) isValidDifficulty(_difficulty) {
        difficulty = _difficulty;
    }

    /*
        functions
    */

    function registerModel(
        Hash _modelContentId,
        string calldata _modelName,
        string calldata _modelDescription,
        address _modelOwnerAddress
    ) external validateModelParameters(_modelName, _modelDescription) {
        model.contentId = _modelContentId;
        model.name = _modelName;
        model.description = _modelDescription;
        model.ownerAddress = _modelOwnerAddress;
        model.isDisabled = false;

        emit ModelRegistered(_modelContentId, _modelOwnerAddress);
    }

    function getModel() external view returns (Model memory) {
        return model;
    }

    function updateModel(
        string calldata _modelName,
        string calldata _modelDescription
    )
        external
        isModelOwner(msg.sender)
        validateModelParameters(_modelName, _modelDescription)
    {
        model.name = _modelName;
        model.description = _modelDescription;
    }

    function disableModel() external isModelOwner(msg.sender) {
        model.isDisabled = true;
    }

    function commit(Hash _merkleRoot) external {
        Hash _commitmentId = _generateCommitmentId(
            model.contentId,
            _merkleRoot
        );
        uint8 _difficulty = difficulty;
        Hash _challenge = Hash.wrap(Challenge.generateChallenge(_difficulty));

        commitments.push(_commitmentId);
        proverAddressToCommitments[msg.sender].push(_commitmentId);
        commitmentIdToCommitment[_commitmentId] = Commitment({
            id: _commitmentId,
            modelContentId: model.contentId,
            merkleRoot: _merkleRoot,
            challenge: _challenge,
            difficulty: _difficulty,
            proverAddress: msg.sender,
            isRevealed: false
        });

        emit Committed(_commitmentId, msg.sender, _challenge);
    }

    function getCommitment(
        Hash _commitmentId
    )
        external
        view
        checkIfCommitmentExists(_commitmentId)
        onlyOwner
        returns (Commitment memory)
    {
        return commitmentIdToCommitment[_commitmentId];
    }

    function getCommitmentsOfModel(
        uint32 _offset,
        uint32 _limit
    )
        external
        view
        validateOffsetParameter(_offset, commitments.length)
        validateLimitParameter(_limit)
        onlyOwner
        returns (Hash[] memory)
    {
        return _paginateCommitments(commitments, _offset, _limit);
    }

    function getCommitmentsOfProver(
        uint32 _offset,
        uint32 _limit
    )
        external
        view
        validateOffsetParameter(
            _offset,
            proverAddressToCommitments[msg.sender].length
        )
        validateLimitParameter(_limit)
        returns (Hash[] memory)
    {
        return
            _paginateCommitments(
                proverAddressToCommitments[msg.sender],
                _offset,
                _limit
            );
    }

    function updateChallenge(
        Hash _commitmentId
    )
        external
        checkIfCommitmentExists(_commitmentId)
        isValidProver(commitmentIdToCommitment[_commitmentId].proverAddress)
    {
        uint8 _difficulty = difficulty;
        Hash _challenge = Hash.wrap(Challenge.generateChallenge(_difficulty));
        commitmentIdToCommitment[_commitmentId].challenge = _challenge;
        commitmentIdToCommitment[_commitmentId].difficulty = _difficulty;

        emit ChallengeUpdated(_commitmentId, msg.sender, _challenge);
    }

    function getDifficulty() external view onlyOwner returns (uint8) {
        return difficulty;
    }

    function updateDifficulty(
        uint8 _difficulty
    ) external isValidDifficulty(_difficulty) onlyOwner {
        difficulty = _difficulty;
    }

    function reveal(
        Hash _commitmentId,
        bytes32[] calldata _merkleProofs,
        bool[] calldata _proofFlags,
        bytes32[] memory _leaves
    )
        external
        checkIfCommitmentExists(_commitmentId)
        isValidProver(commitmentIdToCommitment[_commitmentId].proverAddress)
    {
        require(
            commitmentIdToCommitment[_commitmentId].isRevealed == false,
            "commitment already revealed"
        );

        bytes32 _challenge = Hash.unwrap(
            commitmentIdToCommitment[_commitmentId].challenge
        );
        uint8 _difficulty = commitmentIdToCommitment[_commitmentId].difficulty;
        require(
            MerkleTree.verifyLeaves(_challenge, _difficulty, _leaves) == true,
            "invalid leaves"
        );

        bytes32 _merkleRoot = Hash.unwrap(
            commitmentIdToCommitment[_commitmentId].merkleRoot
        );

        require(
            MerkleTree.verifyMerkleProofs(
                _merkleProofs,
                _proofFlags,
                _merkleRoot,
                _leaves
            ) == true,
            "invalid Merkle proofs"
        );

        commitmentIdToCommitment[_commitmentId].isRevealed = true;

        emit CommitmentRevealed(_commitmentId, msg.sender);
    }

    // TODO: enable solhint
    /* solhint-disable */

    // TODO: implement function
    function verify(
        uint256 commitmentId,
        Zkp[] memory zkps
    ) external returns (ZkpWithValidity[] memory zkpVerifications) {}

    /* solhint-enable */

    /// @dev Paginate commitments given array of commitment IDs, offset and limit.
    function _paginateCommitments(
        Hash[] memory _commitmentIds,
        uint32 _offset,
        uint32 _limit
    ) internal pure returns (Hash[] memory) {
        if (_offset + _limit > _commitmentIds.length) {
            _limit = uint32(_commitmentIds.length - _offset);
        }

        Hash[] memory _paginatedCommitments = new Hash[](_limit);
        for (uint32 i = 0; i < _limit; i++) {
            _paginatedCommitments[i] = _commitmentIds[_offset + i];
        }

        return _paginatedCommitments;
    }

    /**
     * @notice Generate commitment ID.
     * @dev Duplicated commitment ID is not allowed.
     * @param _modelContentId Hash (content ID / address of IPFS) of model
     * @param _merkleRoot Root hash of Merkle tree
     * @return commitmentId Commitment ID
     */
    function _generateCommitmentId(
        Hash _modelContentId,
        Hash _merkleRoot
    ) internal view returns (Hash) {
        Hash _commitmentId = Hash.wrap(
            keccak256(
                abi.encodePacked(_modelContentId, _merkleRoot, msg.sender)
            )
        );

        require(
            Hash.unwrap(commitmentIdToCommitment[_commitmentId].id) == "",
            "commitment already exists"
        );

        return _commitmentId;
    }
}
