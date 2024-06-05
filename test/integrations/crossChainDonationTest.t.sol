// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {ControllerGoFundMe} from "../../src/ControllerGoFundMe.sol";
import {ERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {GoFundMe} from "../../src/UsdcGoFundMe.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Receiver} from "../../src/Reciever.sol";
import {Sender} from "../../src/Sender.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {RouterTest, ChainSelectorTest, linkTokenAddress} from "../../src/constants/ConstCCIP.c.sol";

contract CrossChainDonationTest is Test {
    using SafeERC20 for ERC20;

    ERC20Mock public R_UsdcMock;
    ERC20Mock public S_UsdcMock;
    ERC20Mock public R_liknMock;
    ERC20Mock public S_linkMock;
// senedr contract
    Sender sender;

    // receiver contract
    Receiver receiver;
    // controllers
    ControllerGoFundMe controller;
    
    // TOKEN address
    GoFundMe R_UsdcProject;
    ERC20 public R_Usdc;
    ERC20 public S_Usdc;
    ERC20 public R_likn;
    ERC20 public S_link;

    // projects
    GoFundMe public firstProject;
    GoFundMe public twoProject;

    IRouterClient public i_Srouter = IRouterClient(RouterTest.ETHEREUM);
    IRouterClient public i_Rrouter = IRouterClient(RouterTest.POLYGON_AMOY);

    uint256 public gasLimit = 1000000;

    address alice =
        vm.addr(
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        );

    function setUp() public {
      vm.deal(address(RouterTest.ETHEREUM), 10 ether);
        vm.deal(address(this), 10 ether);
        vm.deal(alice, 10 ether);

        //////////////////////////////
        ///// Fetching R_Usdc address //
        //////////////////////////////
        R_UsdcMock = new ERC20Mock();
        R_UsdcMock.mint(address(this), 1000);
        R_UsdcMock.mint(alice, 1000);
        R_Usdc = ERC20(address(R_UsdcMock));

        //////////////////////////////
        ///// linkTokenAddress/ //////
        //////////////////////////////
        R_liknMock = new ERC20Mock();
        R_likn = ERC20(address(R_liknMock));
        S_linkMock = new ERC20Mock();
        S_link = ERC20(address(S_linkMock));

        //////////////////////////////
        ///// Sender   contract //////
        //////////////////////////////
        S_UsdcMock = new ERC20Mock();
        S_Usdc = ERC20(address(S_UsdcMock));
        sender = new Sender(RouterTest.POLYGON_AMOY,address(S_link), address(S_Usdc));
        vm.prank(alice);
        S_UsdcMock.mint(address(sender), 1000);
        S_linkMock.mint(address(this), 1000);

        //////////////////////////////
        ///// Receiver contract //////
        //////////////////////////////

        receiver = new Receiver(RouterTest.ETHEREUM,address(R_Usdc));
        ControllerGoFundMe controllerAddress = receiver.getControllerAddress();
        controller = ControllerGoFundMe(address(controllerAddress));
        controller.createNewProject();
        controller.createNewProject();
        controller.createNewProject();
        address controllerR_Usdc = controller.getUsdcAddress();

        R_UsdcMock.mint(address(RouterTest.ETHEREUM), 100);
        firstProject = controller.getProject(0);
        twoProject = controller.getProject(1);
        vm.deal(address(receiver), 10 ether);
        //////////////////////////////
        /// Config Receiver Sender ///
        //////////////////////////////
        sender.setGasLimitAndRecieverForDestinationChain(ChainSelectorTest.POLYGON_AMOY, gasLimit, address(receiver));
        receiver.setSenderForSourceChain(ChainSelectorTest.ETHEREUM, address(sender));

        //////////////////////////////
        ///// Console logs  /// //////
        //////////////////////////////
        console.log("R_Usdc", address(R_Usdc));
        console.log("Alice", address(alice));
        console.log("sender", address(sender));
        console.log("receiver", address(receiver));
        console.log("controller", address(controller));
        console.log("firstProject", address(firstProject));
    }

    function testUsdcAddressCCIP() public {
        address testR_Usdc = firstProject.getUsdAddress();

        assertEq(testR_Usdc, address(R_Usdc));
    }

    function testCrossChainDonation() public {

        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: address(R_Usdc),
            amount: 20
        });
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver), // ABI-encoded receiver address
            data: abi.encode(1, 20), // Encode the project index and amount
            tokenAmounts: tokenAmounts, // The amount and type of token being transferred
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit
                Client.EVMExtraArgsV1({gasLimit: gasLimit})
            ),
            // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            feeToken: address(S_link)
        });
            Client.Any2EVMMessage memory dataPackage = Client.Any2EVMMessage({
            messageId: bytes32(0),
            sourceChainSelector: ChainSelectorTest.ETHEREUM,
            sender: abi.encode(address(sender)),
            data: abi.encode(evm2AnyMessage),
            destTokenAmounts: tokenAmounts
        });
        vm.prank(0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59);
        receiver.ccipReceive(dataPackage);
    }
}
