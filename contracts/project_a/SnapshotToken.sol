pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library ArrayUtils {
    function findUpperBound(uint256[] storage _array, uint256 _element) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = _array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            if (_array[mid] > _element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point at `low` is the exclusive upper bound. We will return the inclusive upper bound.

        if (low > 0 && _array[low - 1] == _element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

/**
 * @title SnapshotToken
 *
 * @dev An ERC20 token which enables taking snapshots of accounts' balances.
 * @dev This can be useful to safely implement voting weighed by balance.
 */
contract SnapshotToken is StandardToken {
    using ArrayUtils for uint256[];

    // The 0 id represents no snapshot was taken yet.
    uint256 public currSnapshotId;

    mapping (address => uint256[]) internal snapshotIds;
    mapping (address => uint256[]) internal snapshotBalances;

    event Snapshot(uint256 id);

    function transfer(address _to, uint256 _value) public returns (bool) {
        _updateSnapshot(msg.sender);
        _updateSnapshot(_to);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _updateSnapshot(_from);
        _updateSnapshot(_to);
        return super.transferFrom(_from, _to, _value);
    }

    function snapshot() public returns (uint256) {
        currSnapshotId += 1;
        emit Snapshot(currSnapshotId);
        return currSnapshotId;
    }

    function balanceOfAt(address _account, uint256 _snapshotId) public view returns (uint256) {
        require(_snapshotId > 0 && _snapshotId <= currSnapshotId);

        uint256 idx = snapshotIds[_account].findUpperBound(_snapshotId);

        if (idx == snapshotIds[_account].length) {
            return balanceOf(_account);
        } else {
            return snapshotBalances[_account][idx];
        }
    }

    function _updateSnapshot(address _account) internal {
        if (_lastSnapshotId(_account) < currSnapshotId) {
            snapshotIds[_account].push(currSnapshotId);
            snapshotBalances[_account].push(balanceOf(_account));
        }
    }

    function _lastSnapshotId(address _account) internal view returns (uint256) {
        uint256[] storage snapshots = snapshotIds[_account];

        if (snapshots.length == 0) {
            return 0;
        } else {
            return snapshots[snapshots.length - 1];
        }
    }
}

