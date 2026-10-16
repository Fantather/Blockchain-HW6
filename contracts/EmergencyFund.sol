// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EmergencyFund {
    enum Purpose {
        Treatment,
        Surgery,
        Medicine,
        Accident
    }

    struct Request {
        address beneficiary;
        Purpose purpose;
        uint256 amount;
        uint256 approvals;
        bool paid;
    }

    uint256 public constant PERIOD = 30 days;

    address public clinic;
    uint256 public monthlyAmount;
    uint256 public required;
    address[] private members;
    Request[] private requests;
    mapping(address => bool) public isMember;
    mapping(address => uint256) public nextPaymentAt;
    mapping(uint256 => mapping(address => bool)) public hasApproved;

    event Contributed(address indexed member, uint256 amount);
    event PayoutRequested(uint256 indexed id, address indexed beneficiary, Purpose purpose, uint256 amount);
    event PayoutApproved(uint256 indexed id, address indexed approver, uint256 approvals);
    event PayoutSent(uint256 indexed id, address indexed beneficiary, uint256 amount);

    modifier onlyMember() {
        require(isMember[msg.sender], "only member");
        _;
    }

    modifier onlyClinic() {
        require(msg.sender == clinic, "only clinic");
        _;
    }

    modifier requestExists(uint256 id) {
        require(id < requests.length, "no request with this id");
        _;
    }

    constructor(address[] memory initialMembers, address medicalClinic, uint256 approvalsNeeded, uint256 amountPerMonth) {
        require(initialMembers.length > 0, "no members");
        require(medicalClinic != address(0), "zero address");
        require(approvalsNeeded > 0 && approvalsNeeded <= initialMembers.length, "wrong approvals number");
        require(amountPerMonth > 0, "amount must be more than zero");
        for (uint256 i = 0; i < initialMembers.length; i++) {
            require(!isMember[initialMembers[i]], "duplicate member");
            isMember[initialMembers[i]] = true;
            members.push(initialMembers[i]);
        }
        clinic = medicalClinic;
        required = approvalsNeeded;
        monthlyAmount = amountPerMonth;
    }

    function contribute() public payable onlyMember {
        require(msg.value == monthlyAmount, "wrong contribution amount");
        require(block.timestamp >= nextPaymentAt[msg.sender], "already paid this month");
        nextPaymentAt[msg.sender] = block.timestamp + PERIOD;
        emit Contributed(msg.sender, msg.value);
    }

    function requestPayout(address beneficiary, Purpose purpose, uint256 amount) public onlyMember returns (uint256) {
        require(beneficiary != address(0), "zero address");
        require(amount > 0, "amount must be more than zero");
        requests.push(Request(beneficiary, purpose, amount, 0, false));
        uint256 id = requests.length - 1;
        emit PayoutRequested(id, beneficiary, purpose, amount);
        return id;
    }

    function approve(uint256 id) public onlyMember requestExists(id) {
        Request storage request = requests[id];
        require(!request.paid, "already paid");
        require(!hasApproved[id][msg.sender], "already approved");
        hasApproved[id][msg.sender] = true;
        request.approvals += 1;
        emit PayoutApproved(id, msg.sender, request.approvals);
        if (request.approvals >= required) {
            pay(id);
        }
    }

    function confirmByClinic(uint256 id) public onlyClinic requestExists(id) {
        require(!requests[id].paid, "already paid");
        pay(id);
    }

    function pay(uint256 id) private {
        Request storage request = requests[id];
        require(address(this).balance >= request.amount, "not enough funds");
        request.paid = true;
        emit PayoutSent(id, request.beneficiary, request.amount);
        (bool ok, ) = payable(request.beneficiary).call{value: request.amount}("");
        require(ok, "payout failed");
    }

    function getMembers() public view returns (address[] memory) {
        return members;
    }

    function getRequests() public view returns (Request[] memory) {
        return requests;
    }
}
