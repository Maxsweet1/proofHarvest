// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from
    "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract GulupaEscrow is Ownable {

    // -------------------------
    // STATE VARIABLES
    // -------------------------

    IERC20 public immutable usdc;
    AggregatorV3Interface public priceFeed;

    uint256 public nextAgreementId;

    // Maximum age allowed for Chainlink data.
    uint256 public maxStaleTime = 1 hours;

    // Optional minimum oracle value.
    // Set to 0 if you only want to check that
    // the oracle data is valid and fresh.
    int256 public minimumOracleValue;


    // -------------------------
    // STRUCTS
    // -------------------------

    struct Milestone {
        string name;
        uint256 percentage;
        bool released;
    }

    struct Agreement {
        address farmer;
        uint256 totalAmount;
        bool funded;
        Milestone[] milestones;
    }


    // -------------------------
    // STORAGE
    // -------------------------

    mapping(uint256 => Agreement) private agreements;


    // -------------------------
    // EVENTS
    // -------------------------

    event AgreementCreated(
        uint256 indexed agreementId,
        address indexed farmer,
        uint256 totalAmount
    );

    event AgreementFunded(
        uint256 indexed agreementId,
        uint256 amount
    );

    event MilestoneReleased(
        uint256 indexed agreementId,
        uint256 indexed milestoneIndex,
        uint256 amount
    );


    // -------------------------
    // CONSTRUCTOR
    // -------------------------

    constructor(
        address usdcAddress,
        address priceFeedAddress,
        int256 minimumOracleValue_
    )
        Ownable(msg.sender)
    {
        require(usdcAddress != address(0), "Invalid USDC address");
        require(priceFeedAddress != address(0), "Invalid price feed");

        usdc = IERC20(usdcAddress);

        priceFeed =
            AggregatorV3Interface(priceFeedAddress);

        minimumOracleValue =
            minimumOracleValue_;
    }


    // -------------------------
    // CREATE AGREEMENT
    // -------------------------

    function createAgreement(
        address farmer,
        uint256 totalAmount,
        string[] calldata milestoneNames,
        uint256[] calldata percentages
    )
        external
        onlyOwner
    {
        require(farmer != address(0), "Invalid farmer");
        require(totalAmount > 0, "Amount must be greater than zero");

        require(
            milestoneNames.length == percentages.length,
            "Length mismatch"
        );

        require(
            milestoneNames.length > 0,
            "No milestones"
        );

        uint256 totalPercentage;

        for (uint256 i = 0; i < percentages.length; i++) {
            totalPercentage += percentages[i];
        }

        require(
            totalPercentage == 100,
            "Percentages must equal 100"
        );

        uint256 agreementId = nextAgreementId;

        Agreement storage agreement =
            agreements[agreementId];

        agreement.farmer = farmer;
        agreement.totalAmount = totalAmount;

        for (uint256 i = 0; i < milestoneNames.length; i++) {

            agreement.milestones.push(
                Milestone({
                    name: milestoneNames[i],
                    percentage: percentages[i],
                    released: false
                })
            );
        }

        nextAgreementId++;

        emit AgreementCreated(
            agreementId,
            farmer,
            totalAmount
        );
    }


    // -------------------------
    // FUND ESCROW
    // -------------------------

    function deposit(
        uint256 agreementId
    )
        external
    {
        Agreement storage agreement =
            agreements[agreementId];

        require(
            agreement.farmer != address(0),
            "Agreement does not exist"
        );

        require(
            !agreement.funded,
            "Already funded"
        );

        // Set before external call.
        agreement.funded = true;

        require(
            usdc.transferFrom(
                msg.sender,
                address(this),
                agreement.totalAmount
            ),
            "USDC deposit failed"
        );

        emit AgreementFunded(
            agreementId,
            agreement.totalAmount
        );
    }


    // -------------------------
    // CHAINLINK ORACLE CHECK
    // -------------------------

    function checkOracle()
        public
        view
        returns (int256)
    {
        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        require(
            answer > 0,
            "Invalid oracle answer"
        );

        require(
            updatedAt != 0,
            "Oracle round incomplete"
        );

        require(
            answeredInRound >= roundId,
            "Stale oracle round"
        );

        require(
            block.timestamp - updatedAt <= maxStaleTime,
            "Oracle data too old"
        );

        if (minimumOracleValue > 0) {
            require(
                answer >= minimumOracleValue,
                "Oracle value below minimum"
            );
        }

        return answer;
    }


    // -------------------------
    // RELEASE MILESTONE
    // -------------------------

    function releaseMilestone(
        uint256 agreementId,
        uint256 milestoneIndex
    )
        external
        onlyOwner
    {
        Agreement storage agreement =
            agreements[agreementId];

        require(
            agreement.funded,
            "Agreement not funded"
        );

        require(
            milestoneIndex < agreement.milestones.length,
            "Invalid milestone"
        );

        Milestone storage milestone =
            agreement.milestones[milestoneIndex];

        require(
            !milestone.released,
            "Milestone already released"
        );

        // Chainlink acts as the gate.
        // If the oracle check fails,
        // the entire transaction reverts.
        checkOracle();

        uint256 payment =
            (agreement.totalAmount *
                milestone.percentage) / 100;

        // Mark released before sending USDC.
        milestone.released = true;

        require(
            usdc.transfer(
                agreement.farmer,
                payment
            ),
            "USDC payment failed"
        );

        emit MilestoneReleased(
            agreementId,
            milestoneIndex,
            payment
        );
    }


    // -------------------------
    // VIEW FUNCTIONS
    // -------------------------

    function getAgreement(
        uint256 agreementId
    )
        external
        view
        returns (
            address farmer,
            uint256 totalAmount,
            bool funded,
            uint256 milestoneCount
        )
    {
        Agreement storage agreement =
            agreements[agreementId];

        return (
            agreement.farmer,
            agreement.totalAmount,
            agreement.funded,
            agreement.milestones.length
        );
    }


    function getMilestone(
        uint256 agreementId,
        uint256 milestoneIndex
    )
        external
        view
        returns (
            string memory name,
            uint256 percentage,
            bool released
        )
    {
        Milestone storage milestone =
            agreements[agreementId]
                .milestones[milestoneIndex];

        return (
            milestone.name,
            milestone.percentage,
            milestone.released
        );
    }


    // -------------------------
    // OWNER SETTINGS
    // -------------------------

    function setPriceFeed(
        address newPriceFeed
    )
        external
        onlyOwner
    {
        require(
            newPriceFeed != address(0),
            "Invalid price feed"
        );

        priceFeed =
            AggregatorV3Interface(newPriceFeed);
    }


    function setMinimumOracleValue(
        int256 newMinimum
    )
        external
        onlyOwner
    {
        minimumOracleValue =
            newMinimum;
    }


    function setMaxStaleTime(
        uint256 newMaxStaleTime
    )
        external
        onlyOwner
    {
        maxStaleTime =
            newMaxStaleTime;
    }
}
