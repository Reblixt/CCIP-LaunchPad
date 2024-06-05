// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

library RouterTest {
    address public constant ETHEREUM =
        0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
    address public constant POLYGON_AMOY =
        0x9C32fCB86BF0f4a1A8921a9Fe46de3198bb884B2;
    address public constant FUJI = 0xF694E193200268f9a4868e4Aa017A0118C9a8177;
    address public constant BASE = 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93;
    address public constant ARBITRUM =
        0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165;
    address public constant OPTIMISM =
        0x114A20A10b43D4115e5aeef7345a1A71d2a60C57;
}

library ChainSelectorTest {
    uint64 public constant ETHEREUM = 16015286601757825753;
    uint64 public constant POLYGON_AMOY = 16281711391670634445;
    uint64 public constant FUJI = 14767482510784806043;
    uint64 public constant BASE = 10344971235874465080;
    uint64 public constant ARBITRUM = 3478487238524512106;
    uint64 public constant OPTIMISM = 5224473277236331295;
}

library linkTokenAddress {
    address public constant ETHEREUM =
        0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address public constant POLYGON_AMOY =
        0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904;
    address public constant FUJI = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
    address public constant BASE = 0xE4aB69C077896252FAFBD49EFD26B5D171A32410;
    address public constant ARBITRUM =
        0xb1D4538B4571d411F07960EF2838Ce337FE1E80E;
    address public constant OPTIMISM =
        0xE4aB69C077896252FAFBD49EFD26B5D171A32410;
}
