// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/* is ERC721Votes */
contract WrappedIndexMarkerVotes {
    // override _getVotingUnits to add (ownsRelevantTomb(account) ? 1 : 0) * tomb holder voting weight.
    // to calculate ownsRelevantTomb(account) check if msg.sender is a tomb dao governor (via registry
    // and/or erc165), if so, get dao's tomb contract address & token id from public getter in governor,
    // then check if account owns that token
    // tomb holder voting weight is configurable by WrappedIndexMarkerVotes dao and/or tomb multisig.
}
