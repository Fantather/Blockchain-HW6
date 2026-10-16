// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EducationGrant {
    enum Goal {
        Admission,
        CourseCompleted,
        Graduation
    }

    struct Student {
        bool registered;
        bool frozen;
        uint256 received;
    }

    uint256 public constant PASS_GRADE = 60;

    address public owner;
    mapping(address => Student) public students;
    mapping(address => mapping(Goal => bool)) public goalPaid;

    event Deposited(address indexed from, uint256 amount);
    event StudentRegistered(address indexed student);
    event GoalConfirmed(address indexed student, Goal goal, uint256 grade, uint256 amount);
    event GoalFailed(address indexed student, Goal goal, uint256 grade);
    event StudentFrozen(address indexed student);
    event StudentUnfrozen(address indexed student);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier onlyRegistered(address student) {
        require(students[student].registered, "student is not registered");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        require(msg.value > 0, "send some ether");
        emit Deposited(msg.sender, msg.value);
    }

    function registerStudent(address student) public onlyOwner {
        require(student != address(0), "zero address");
        require(!students[student].registered, "already registered");
        students[student].registered = true;
        emit StudentRegistered(student);
    }

    function baseGrant(Goal goal) public pure returns (uint256) {
        if (goal == Goal.Admission) {
            return 1 ether;
        }
        if (goal == Goal.CourseCompleted) {
            return 2 ether;
        }
        return 3 ether;
    }

    function grantFor(Goal goal, uint256 grade) public pure returns (uint256) {
        if (grade >= 90) {
            return baseGrant(goal);
        }
        if (grade >= 75) {
            return baseGrant(goal) * 75 / 100;
        }
        return baseGrant(goal) / 2;
    }

    function confirmGoal(address student, Goal goal, uint256 grade) public onlyOwner onlyRegistered(student) {
        Student storage info = students[student];
        require(!info.frozen, "student is frozen");
        require(!goalPaid[student][goal], "goal already paid");
        require(grade <= 100, "grade is above 100");

        if (grade < PASS_GRADE) {
            info.frozen = true;
            emit GoalFailed(student, goal, grade);
            emit StudentFrozen(student);
            return;
        }

        uint256 amount = grantFor(goal, grade);
        require(address(this).balance >= amount, "not enough funds");

        goalPaid[student][goal] = true;
        info.received += amount;
        emit GoalConfirmed(student, goal, grade, amount);
        (bool ok, ) = payable(student).call{value: amount}("");
        require(ok, "payout failed");
    }

    function freezeStudent(address student) public onlyOwner onlyRegistered(student) {
        require(!students[student].frozen, "already frozen");
        students[student].frozen = true;
        emit StudentFrozen(student);
    }

    function unfreezeStudent(address student) public onlyOwner onlyRegistered(student) {
        require(students[student].frozen, "not frozen");
        students[student].frozen = false;
        emit StudentUnfrozen(student);
    }
}
