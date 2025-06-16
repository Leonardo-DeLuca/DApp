// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CertificateRegistry is Ownable {
    struct Certificate {
        address student;
        string studentName;
        string courseName;
        uint256 issueDate;
        bool exists;
    }

    mapping(bytes32 => Certificate) private certificates;
    mapping(address => bytes32[]) private certificatesByStudent;

    event CertificateIssued(bytes32 indexed certId, address indexed student, string studentName, string courseName, uint256 issueDate);

    constructor() Ownable(msg.sender) {}

    /// @notice Emite um certificado para um aluno. Somente o owner (professor) pode chamar.
    /// @param student Endereço de carteira do aluno.
    /// @param studentName Nome completo do aluno.
    /// @param courseName Nome do curso ou evento.
    /// @param issueDate Timestamp Unix da emissão.
    /// @return certId Identificador único do certificado.
    function issueCertificate(
        address student,
        string calldata studentName,
        string calldata courseName,
        uint256 issueDate
    ) external onlyOwner returns (bytes32 certId) {
        certId = keccak256(abi.encodePacked(student, studentName, courseName, issueDate));
        require(!certificates[certId].exists, "Certificado ja emitido");

        certificates[certId] = Certificate({
            student: student,
            studentName: studentName,
            courseName: courseName,
            issueDate: issueDate,
            exists: true
        });
        certificatesByStudent[student].push(certId);

        emit CertificateIssued(certId, student, studentName, courseName, issueDate);
    }

    /// @notice Verifica se um certificado existe e retorna seus dados.
    /// @param certId Identificador único do certificado.
    /// @return student Endereço do aluno.
    /// @return studentName Nome do aluno.
    /// @return courseName Nome do curso/evento.
    /// @return issueDate Data da emissão em formato legível.
    /// @return valid Se o certificado existe.
    function verifyCertificate(bytes32 certId)
        external
        view
        returns (
            address student,
            string memory studentName,
            string memory courseName,
            string memory issueDate,
            bool valid
        )
    {
        Certificate memory cert = certificates[certId];
        string memory formattedDate = _formatDate(cert.issueDate);
        return (
            cert.student,
            cert.studentName,
            cert.courseName,
            formattedDate,
            cert.exists
        );
    }

    /// @notice Retorna lista de IDs de certificados de um aluno.
    /// @param student Endereço do aluno.
    /// @return ids Array de certIds emitidos para o aluno.
    function getCertificatesByStudent(address student) external view returns (bytes32[] memory ids) {
        return certificatesByStudent[student];
    }

    /// @dev Converte timestamp para string no formato YYYY-MM-DD (simplificado).
    function _formatDate(uint256 timestamp) internal pure returns (string memory) {
        uint256 daysSinceEpoch = timestamp / 86400;
        uint256 year = 1970 + daysSinceEpoch / 365;
        uint256 month = (daysSinceEpoch % 365) / 30 + 1;
        uint256 day = (daysSinceEpoch % 365) % 30 + 1;

        return string(
            abi.encodePacked(
                _uintToStr(year), "-",
                month < 10 ? "0" : "", _uintToStr(month), "-",
                day < 10 ? "0" : "", _uintToStr(day)
            )
        );
    }

    function _uintToStr(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}