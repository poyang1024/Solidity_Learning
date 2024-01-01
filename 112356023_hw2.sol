// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract GradesContract {
    address public teacher;

    mapping (address => Grades) studentGrades;
    mapping (string => bool) subjectExists; // 追蹤 subject 是否已存在
    string[] internal subjectNames; // 儲存已存在的科目名稱

    address[] studentIds;

    struct Grades {
        mapping (string => uint) subjectGrades;
        bool Registered;
    }

    // 發送通知學科成績更改的事件
    event SubjectGradeUpdated(address studentId, string subjectName, uint subjectGrade);

    constructor() {
        teacher = msg.sender;
    }

    modifier onlyTeacherOrStudent(address studentId) {
        require(isTeacher() || isGradesOf(studentId), "Only the student who owns these grades or the teacher can call this method");
        _;
    }
    modifier onlyTeacher() {
        require(msg.sender == teacher, "Only the teacher can call this method");
        _;
    }

    function isTeacher() internal view returns (bool) {
        return (msg.sender == teacher);
    }

    function isGradesOf(address input) internal view returns (bool) {
        return (msg.sender == input);
    }

     function addSubject(string memory subjectName) external onlyTeacher {
        // 檢查 subject 是否已存在
        require(!subjectExists[subjectName], "Subject already exists");
        subjectNames.push(subjectName);

        // 新增後標記 subject 已存在
        subjectExists[subjectName] = true;
    }

    function getSubjectGrade(address studentId, string memory subjectName) external view returns (uint) {
        //  subject 是否已存在
        require(subjectExists[subjectName], "Subject does not exist");
        return studentGrades[studentId].Registered ? studentGrades[studentId].subjectGrades[subjectName] : 0;
    }

    function putSubjectGrade(address studentId, string memory subjectName, uint subjectGrade) external onlyTeacher {
        require(subjectExists[subjectName], "Subject does not exist");
        studentGrades[studentId].Registered = true;
        studentGrades[studentId].subjectGrades[subjectName] = subjectGrade;
        studentIds.push(studentId);
        // Emit an event to notify the change in subject grade
        emit SubjectGradeUpdated(studentId, subjectName, subjectGrade);
    }


    function getGradesSum(address studentId) public view onlyTeacherOrStudent(studentId) returns (uint) {
        uint totalGrades = 0;

        // Iterate through the subjects and sum the grades
        for (uint i = 0; i < subjectNames.length; i++) {
            string memory subjectName = subjectNames[i];
            totalGrades += studentGrades[studentId].subjectGrades[subjectName];
        }

        return totalGrades;
    }


    function getGradesAverage(address studentId) external view onlyTeacherOrStudent(studentId) returns (uint) {
        uint sum = getGradesSum(studentId);
        return subjectNames.length > 0 ? sum / subjectNames.length : 0;
    }

    function getClassGradesAverage() external view onlyTeacher returns (uint) {

        // Iterate all the students and calculate their average grades
        uint sum = 0;
        uint studentNum = studentIds.length;
        
        for (uint i = 0; i < studentNum; i++) {
            sum = sum + getGradesSum(studentIds[i]);
        }
        
        return (sum / studentNum) / subjectNames.length;
    }

}