// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

interface IndexInterface {
  function master() external view returns (address);
  function build(address _owner, uint accountVersion, address _origin) external returns (address _account);
}

contract Registry {

  event LogAddChief(address indexed chief);
  event LogRemoveChief(address indexed chief);
  event LogAddSigner(address indexed signer);
  event LogRemoveSigner(address indexed signer);
  event LogUpdatePoolLogic(address token, address newLogic);
  event LogUpdateFee(address token, uint newFee);
  event LogUpdateCap(address token, uint newFee);
  event LogAddPool(address indexed token, address indexed pool);
  event LogRemovePool(address indexed token, address indexed pool);
  event LogAddSettleLogic(address indexed token, address indexed logic);
  event LogRemoveSettleLogic(address indexed token, address indexed logic);

  IndexInterface public constant instaIndex = IndexInterface(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);

  mapping (address => bool) public chief;
  mapping (address => bool) public signer;
  mapping (address => address) public poolToken;
  mapping (address => address) public poolLogic;
  mapping (address => uint) public poolCap;
  mapping (address => uint) public fee;
  mapping (address => mapping(address => bool)) public settleLogic;

  modifier isMaster() {
    require(msg.sender == instaIndex.master(), "not-master");
    _;
  }

  modifier isChief() {
    require(chief[msg.sender] || msg.sender == instaIndex.master(), "not-chief");
    _;
  }

  /**
    * @dev Enable New Chief.
    * @param _chief Address of the new chief.
  */
  function enableChief(address _chief) external isMaster {
    require(_chief != address(0), "address-not-valid");
    require(!chief[_chief], "chief-already-enabled");
    chief[_chief] = true;
    emit LogAddChief(_chief);
  }

  /**
    * @dev Disable Chief.
    * @param _chief Address of the existing chief.
  */
  function disableChief(address _chief) external isMaster {
    require(_chief != address(0), "address-not-valid");
    require(chief[_chief], "chief-already-disabled");
    delete chief[_chief];
    emit LogRemoveChief(_chief);
  }

  /**
    * @dev Enable New Signer.
    * @param _signer Address of the new signer.
  */
  function enableSigner(address _signer) external isChief {
      require(_signer != address(0), "invalid-address");
      require(!signer[_signer], "signer-already-enabled");
      signer[_signer] = true;
      emit LogAddSigner(_signer);
  }

  /**
    * @dev Disable Signer.
    * @param _signer Address of the existing signer.
  */
  function disableSigner(address _signer) external isChief {
      require(_signer != address(0), "invalid-address");
      require(signer[_signer], "signer-already-disabled");
      delete signer[_signer];
      emit LogRemoveSigner(_signer);
  }

  /**
    * @dev Add New Pool
    * @param _token ERC20 token address
    * @param pool pool address
  */
  function addPool(address _token, address pool) external isMaster {
    require(_token != address(0) && pool != address(0), "invalid-token-address");
    require(poolToken[_token] == address(0), "pool-already-added");
    poolToken[_token] = pool;
    emit LogAddPool(_token, pool);
  }

  /**
    * @dev Remove Pool
    * @param _token ERC20 token address
  */
  function removePool(address _token) external isMaster {
    require(_token != address(0), "invalid-token-address");
    require(poolToken[_token] != address(0), "pool-already-removed");
    address poolAddr = poolToken[_token];
    delete poolToken[_token];
    emit LogRemovePool(_token, poolAddr);
  }

  /**
    * @dev update pool rate logic
    * @param _token pool address
    * @param _newLogic new rate logic address
  */
  function updatePoolLogic(address _token, address _newLogic) external isMaster {
    address _pool = poolToken[_token];
    require(_pool != address(0), "invalid-pool");
    require(_newLogic != address(0), "invalid-address");
    require(poolLogic[_pool] != _newLogic, "same-pool-logic");
    poolLogic[_pool] = _newLogic;
    emit LogUpdatePoolLogic(_pool, _newLogic);
  }

  /**
    * @dev update pool fee
    * @param _token pool address
    * @param _newFee new fee amount
  */
  function updateFee(address _token, uint _newFee) external isMaster {
    address _pool = poolToken[_token];
    require(_pool != address(0), "invalid-pool");
    require(_newFee < 3 * 10 ** 17, "insure-fee-limit-reached");
    require(fee[_pool] != _newFee, "same-pool-fee");
    fee[_pool] = _newFee;
    emit LogUpdateFee(_pool, _newFee);
  }

  /**
    * @dev update pool fee
    * @param _token pool address
    * @param _newCap new fee amount
  */
  function updateCap(address _token, uint _newCap) external isMaster {
    address _pool = poolToken[_token];
    require(_pool != address(0), "invalid-pool");
    poolCap[_pool] = _newCap;
    emit LogUpdateCap(_pool, _newCap);
  }

  function addSettleLogic(address _token, address _logic) external isMaster {
    address _pool = poolToken[_token];
    require(_pool != address(0), "invalid-pool");
    settleLogic[_pool][_logic] = true;
    emit LogAddSettleLogic(_pool, _logic);
  }

  function removeSettleLogic(address _token, address _logic) external isMaster {
    address _pool = poolToken[_token];
    require(_pool != address(0), "invalid-pool");
    delete settleLogic[_pool][_logic];
    emit LogRemoveSettleLogic(_pool, _logic);
  }

  function checkSettleLogics(address _pool, address[] calldata _logics) external view returns(bool) {
    for (uint i = 0; i < _logics.length; i++) {
      if (!settleLogic[_pool][_logics[i]]) {
        return false;
      }
    }
    return true;
  }

  constructor(address _chief) public {
    chief[_chief] = true;
    emit LogAddChief(_chief);
  } 
}
