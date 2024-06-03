// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

interface MyToken {
    function totalSupply() external view returns (uint256);

    function mint(address _to, uint256 _value) external returns (bool);

    function burnFrom(address _to, uint256 _value) external returns (bool);
}

contract Carom is ReentrancyGuard {
    // Events
    event TokenExchange(
        address indexed buyer,
        int128 soldId,
        uint256 tokensSold,
        int128 boughtId,
        uint256 tokensBought
    );

    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 tokenSupply
    );

    uint256 private constant FEE_DENOMINATOR = 10 ** 10;
    uint256 private constant PRECISION = 10 ** 18;

    address[3] public coins;
    uint256[3] public balances;
    uint256 public fee; // fee * 1e10
    uint256 public admin_fee; // admin_fee * 1e10

    address public owner;
    MyToken public token;

    uint256[3] private RATES = [1 ether, 1 ether, 1 ether];

    constructor(
        address _owner,
        address[3] memory _coins,
        address _pool_token,
        uint256 _fee,
        uint256 _admin_fee
    ) {
        for (uint256 i = 0; i < 3; i++) {
            require(_coins[i] != address(0), "Coin address cannot be zero");
        }
        coins = _coins;
        fee = _fee;
        admin_fee = _admin_fee;
        owner = _owner;
        token = MyToken(_pool_token);
    }

    function _xp() internal view returns (uint256[3] memory) {
        uint256[3] memory result;
        for (uint256 i = 0; i < 3; i++) {
            result[i] = (RATES[i] * balances[i]) / PRECISION;
        }
        return result;
    }

    function _xp_mem(
        uint256[3] memory _balances
    ) internal view returns (uint256[3] memory) {
        uint256[3] memory result;
        for (uint256 i = 0; i < 3; i++) {
            result[i] = (RATES[i] * _balances[i]) / PRECISION;
        }
        return result;
    }

    function get_D(
        uint256[3] memory xp,
        uint256 amp
    ) internal pure returns (uint256) {
        uint256 S = 0;
        for (uint256 i = 0; i < 3; i++) {
            S += xp[i];
        }
        if (S == 0) {
            return 0;
        }

        uint256 D = S;
        uint256 Ann = amp * 3;
        for (uint i = 0; i < 255; i++) {
            uint256 D_P = D;
            for (uint256 j = 0; j < 3; j++) {
                D_P = (D_P * D) / (xp[j] * 3);
            }
            uint256 Dprev = D;
            D = ((Ann * S + D_P * 3) * D) / ((Ann - 1) * D + (3 + 1) * D_P);

            if (D > Dprev && D - Dprev <= 1) {
                break;
            } else if (Dprev - D <= 1) {
                break;
            }
        }
        return D;
    }

    function get_D_mem(
        uint256[3] memory _balances,
        uint256 amp
    ) internal view returns (uint256) {
        return get_D(_xp_mem(_balances), amp);
    }

    function getVirtualPrice() external view returns (uint256) {
        uint256 D = get_D(_xp(), 2000);
        uint256 tokenSupply = token.totalSupply();
        if (tokenSupply == 0) {
            return 0;
        }
        return (D * PRECISION) / tokenSupply;
    }

    function calcTokenAmount(
        uint256[3] calldata amounts,
        bool deposit
    ) external view returns (uint256) {
        uint256[3] memory _balances = balances;
        uint256 D0 = get_D_mem(_balances, 2000);

        for (uint i = 0; i < 3; i++) {
            if (deposit) {
                _balances[i] += amounts[i];
            } else {
                require(_balances[i] >= amounts[i], "Insufficient balance");
                _balances[i] -= amounts[i];
            }
        }

        uint256 D1 = get_D_mem(_balances, 2000);
        uint256 tokenAmount = token.totalSupply();
        uint256 diff = deposit ? D1 - D0 : D0 - D1;

        if (D0 == 0) {
            return 0;
        }

        return (diff * tokenAmount) / D0;
    }

    function initialAddLiquidity(
        uint256[3] calldata amounts,
        uint256 minMintAmount
    ) external payable nonReentrant {
        uint256[3] memory newBalances = balances;
        uint256[3] memory fees;

        require(
            amounts[0] > 0 && amounts[1] > 0 && amounts[2] > 0,
            "Initial deposit requires all coins to be non-zero"
        );

        for (uint256 i = 0; i < 3; ++i) {
            if (amounts[i] > 0) {
                IERC20 inCoin = IERC20(coins[i]);
                uint256 balanceBefore = inCoin.balanceOf(address(this));
                inCoin.transferFrom(msg.sender, address(this), amounts[i]);
                uint256 balanceAfter = inCoin.balanceOf(address(this));
                newBalances[i] = balanceAfter - balanceBefore;
            }
        }

        uint256 D1 = get_D_mem(newBalances, 2000);
        uint256 mintAmount = (D1 * 1e18) / PRECISION;

        require(
            mintAmount >= minMintAmount,
            "Mint amount below minimum mint amount"
        );

        token.mint(msg.sender, mintAmount);

        for (uint256 i = 0; i < 3; ++i) {
            balances[i] = newBalances[i];
        }

        uint256[] memory dynamicAmounts = new uint256[](3);
        uint256[] memory dynamicFees = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            dynamicAmounts[i] = amounts[i];
            dynamicFees[i] = fees[i];
        }

        emit AddLiquidity(
            msg.sender,
            dynamicAmounts,
            dynamicFees,
            D1,
            mintAmount
        );
    }

    function addLiquidity(
        uint256[3] calldata amounts,
        uint256 minMintAmount
    ) external payable nonReentrant {
        uint256[3] memory fees;
        uint256 _fee = (fee * 3) / (4 * (3 - 1));
        uint256 _adminFee = admin_fee;

        uint256 tokenSupply = token.totalSupply();
        require(tokenSupply > 0, "Token supply must be greater than 0");

        uint256 D0 = get_D_mem(balances, 2000);
        uint256[3] memory newBalances = balances;

        for (uint256 i = 0; i < 3; ++i) {
            if (amounts[i] > 0) {
                IERC20 inCoin = IERC20(coins[i]);
                uint256 balanceBefore = inCoin.balanceOf(address(this));
                inCoin.transferFrom(msg.sender, address(this), amounts[i]);
                uint256 balanceAfter = inCoin.balanceOf(address(this));
                newBalances[i] = balances[i] + (balanceAfter - balanceBefore);
            }
        }

        uint256 D1 = get_D_mem(newBalances, 2000);
        require(D1 > D0, "D1 must be greater than D0");

        uint256 mintAmount = (tokenSupply * (D1 - D0)) / D0;
        require(
            mintAmount >= minMintAmount,
            "Mint amount below minimum mint amount"
        );

        token.mint(msg.sender, mintAmount);

        for (uint256 i = 0; i < 3; ++i) {
            uint256 idealBalance = (D1 * balances[i]) / D0;
            uint256 difference = idealBalance > newBalances[i]
                ? idealBalance - newBalances[i]
                : newBalances[i] - idealBalance;
            fees[i] = (_fee * difference) / FEE_DENOMINATOR;
            newBalances[i] -= fees[i];
            balances[i] =
                newBalances[i] -
                (fees[i] * _adminFee) /
                FEE_DENOMINATOR;
        }

        uint256[] memory dynamicAmounts = new uint256[](3);
        uint256[] memory dynamicFees = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            dynamicAmounts[i] = amounts[i];
            dynamicFees[i] = fees[i];
        }

        emit AddLiquidity(
            msg.sender,
            dynamicAmounts,
            dynamicFees,
            D1,
            tokenSupply + mintAmount
        );
    }

    function SCTU(int128 value) internal pure returns (uint256) {
        require(value >= 0, "Negative value not allowed");
        return uint256(uint128(value));
    }

    function get_y(
        int128 i,
        int128 j,
        uint256 x,
        uint256[3] memory xp_
    ) internal pure returns (uint256) {
        require(i != j, "Same coin");
        require(j >= 0 && SCTU(j) < 3, "j out of range");
        require(i >= 0 && SCTU(i) < 3, "i out of range");

        uint256 D = get_D(xp_, 2000);
        uint256 c = D;
        uint256 S_ = 0;
        uint256 Ann = 6000;

        uint256 _x = 0;
        for (uint256 _i = 0; _i < 3; _i++) {
            if (_i == SCTU(i)) {
                _x = x;
            } else if (_i != SCTU(j)) {
                _x = xp_[_i];
            } else {
                continue;
            }
            S_ += _x;
            c = (c * D) / (_x * 3);
            require(c <= D, "Overflow in c calculation");
        }
        c = (c * D) / (Ann * 3);
        uint256 b = S_ + D / Ann;
        uint256 y_prev = 0;
        uint256 y = D;
        for (uint256 _i = 0; _i < 255; _i++) {
            y_prev = y;
            y = (y * y + c) / (2 * y + b - D);
            if (y > y_prev && y - y_prev <= 1) {
                break;
            } else if (y_prev - y <= 1) {
                break;
            }
            require(y <= y_prev, "Overflow in y calculation");
        }
        return y;
    }

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256) {
        uint256[3] memory rates = RATES;
        uint256[3] memory xp = _xp();

        uint256 x = xp[SCTU(i)] + (dx * rates[SCTU(i)]) / PRECISION;
        uint256 y = get_y(i, j, x, xp);
        uint256 dy = ((xp[SCTU(j)] - y - 1) * PRECISION) / rates[SCTU(j)];
        uint256 _fee = (fee * dy) / FEE_DENOMINATOR;
        return dy - _fee;
    }

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external nonReentrant {
        uint256 index_i = SCTU(i);
        uint256 index_j = SCTU(j);
        address input_coin = coins[index_i];
        address output_coin = coins[index_j];

        uint256 dx_w_fee = _transferInputCoins(input_coin, dx);
        uint256 dy = _performExchange(index_i, index_j, dx_w_fee, min_dy);
        _updateBalancesAndTransferOutput(
            index_i,
            index_j,
            dx_w_fee,
            dy,
            output_coin
        );

        emit TokenExchange(msg.sender, i, dx, j, dy);
    }

    function _transferInputCoins(
        address input_coin,
        uint256 dx
    ) internal returns (uint256) {
        uint256 initial_balance = IERC20(input_coin).balanceOf(address(this));
        bool success = IERC20(input_coin).transferFrom(
            msg.sender,
            address(this),
            dx
        );
        require(success, "Transfer failed");
        return IERC20(input_coin).balanceOf(address(this)) - initial_balance;
    }

    function _performExchange(
        uint256 index_i,
        uint256 index_j,
        uint256 dx_w_fee,
        uint256 min_dy
    ) internal view returns (uint256) {
        uint256[3] memory xp = _xp();
        uint256 x = xp[index_i] + (dx_w_fee * RATES[index_i]) / PRECISION;
        require(x >= xp[index_i], "Overflow in x calculation");

        uint256 y = get_y(
            int128(int256(index_i)),
            int128(int256(index_j)),
            x,
            xp
        );

        uint256 dy = xp[index_j] - y - 1;
        uint256 dy_fee = (dy * fee) / FEE_DENOMINATOR;
        dy = ((dy - dy_fee) * PRECISION) / RATES[index_j];

        require(dy >= min_dy, "Exchange resulted in fewer coins than expected");
        return dy;
    }

    function _updateBalancesAndTransferOutput(
        uint256 index_i,
        uint256 index_j,
        uint256 dx_w_fee,
        uint256 dy,
        address output_coin
    ) internal {
        uint256 dy_admin_fee = (((dy * admin_fee) / FEE_DENOMINATOR) *
            PRECISION) / RATES[index_j];

        balances[index_i] += dx_w_fee;
        balances[index_j] -= (dy + dy_admin_fee);

        bool success = IERC20(output_coin).transfer(msg.sender, dy);
        require(success, "Transfer failed");
    }
}
    
