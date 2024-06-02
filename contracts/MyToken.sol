// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Token is IERC20 {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public minters;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        uint256 initSupply = _initialSupply * (10 ** decimals);
        balanceOf[msg.sender] = initSupply;
        totalSupply = initSupply;
        minters[msg.sender] = true;
        emit Transfer(address(0), msg.sender, initSupply);
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Only minters can perform this action");
        _;
    }

    function addMinter(address _minter) external onlyMinter {
        require(_minter != address(0), "Cannot add zero address as minter");
        minters[_minter] = true;
    }

    function removeMinter(address _minter) external onlyMinter {
        require(_minter != address(0), "Cannot remove zero address as minter");
        minters[_minter] = false;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        if (!minters[msg.sender]) {
            uint256 allowance = _allowances[_from][msg.sender];
            require(allowance >= _value, "Insufficient allowance");
            _allowances[_from][msg.sender] -= _value;
        }
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require(
            _value == 0 || _allowances[msg.sender][_spender] == 0,
            "Cannot approve non-zero allowance"
        );
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function mint(
        address _to,
        uint256 _value
    ) external onlyMinter returns (bool) {
        require(_to != address(0), "Cannot mint to zero address");
        totalSupply += _value;
        balanceOf[_to] += _value;
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function burnFrom(
        address _to,
        uint256 _value
    ) external onlyMinter returns (bool) {
        require(_to != address(0), "Cannot burn from zero address");
        require(balanceOf[_to] >= _value, "Insufficient balance");
        totalSupply -= _value;
        balanceOf[_to] -= _value;
        emit Transfer(_to, address(0), _value);
        return true;
    }
}
