# Recovery Contracts [![Foundry][foundry-badge]][foundry] [![License: MIT][license-badge]][license]

[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

A (preview of a) protocol for community-minted collections dedicated to existing NFTs on Ethereum. It is currently
unaudited and not deployed anywhere.

This project is a collaboration between Tomb Series and Zora. See this
[mirror post](https://mirror.xyz/cold.tombcouncil.eth/mdt3PIw8PZZ21dLA0OlEwb-1Nd3cMAWR5rFwphUiYxE) for background info
on the Recovery project.

## Structure

- **RecoveryRegistry**: A factory and registry for the Recovery protocol. ERC721 collection Owners can register their
  collection and set default settings. Once the collection is registered, that same contract Owner or token owners can
  create a Recovery instance for one individual token (the "parent token"). A Recovery instance includes the following
  two components.
- **governance**: An upgradeable OpenZeppelin Governor and TimelockController. Both ERC721Votes and ERC20Votes are
  supported as voting tokens. The parent token owner has a configurable extra voting weight.
- **token**: An upgradeable ERC721 which uses URL storage for metadata. The collection supports ERC2981 royalties, which
  default to the current parent token owner, as well as platforms that require an "operator filter". The governance
  module is the owner of this collection, and is capable of minting, burning and other admin functions.
