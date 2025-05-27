// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 문서 공유를 위한 스마트 컨트랙트
contract DocumentSharing {
    // 문서 구조체 정의
    struct Document {
        string title;           // 문서 제목
        string documentHash;    // IPFS 해시값
        address owner;          // 문서 소유자
        bool isPrivate;         // 비공개 여부
        string[] tags;          // 문서 태그
        uint256 viewCount;      // 조회수
        uint256 downloadCount;  // 다운로드 수
        bool isEncrypted;       // 암호화 여부
        string encryptionKey;   // 암호화 키 해시
    }
    
    // 공유 링크 구조체
    struct ShareLink {
        string linkId;          // 링크 ID
        uint256 docId;          // 문서 ID
        uint256 expiryTime;     // 만료 시간
        bool isPasswordProtected; // 비밀번호 보호 여부
        string passwordHash;    // 비밀번호 해시
        uint256 maxUses;        // 최대 사용 횟수
        uint256 currentUses;    // 현재 사용 횟수
    }
    
    // 팀 관련 구조체와 변수 추가
    struct Team {
        string name;
        address owner;
        address[] members;
        mapping(address => bool) isMember;
    }
    
    // 컨트랙트 관리자 주소
    address public admin;
    
    // 문서 ID를 키로 하는 문서 매핑
    mapping(uint256 => Document) public documents;
    
    // 문서 접근 권한 매핑 (문서ID => (사용자주소 => 접근권한))
    mapping(uint256 => mapping(address => bool)) public documentAccess;
    
    // 문서별 접근 권한이 있는 사용자 목록
    mapping(uint256 => address[]) public documentAccessList;
    
    // 공유 링크 매핑
    mapping(string => ShareLink) public shareLinks;
    
    // 팀 매핑
    mapping(uint256 => Team) public teams;
    uint256 public teamCount;
    
    // 사용자의 팀 목록
    mapping(address => uint256[]) public userTeams;
    
    // 전체 문서 수
    uint256 public documentCount;
    
    // 이벤트 정의
    event DocumentCreated(uint256 docId, string title, address owner, string documentHash, bool isPrivate);
    event AccessGranted(uint256 docId, address user);
    event AccessRevoked(uint256 docId, address user);
    event ShareLinkCreated(string linkId, uint256 docId, uint256 expiryTime);
    event TeamCreated(uint256 indexed teamId, string name, address indexed owner);
    event TeamMemberAdded(uint256 indexed teamId, address indexed member);
    event TeamMemberRemoved(uint256 indexed teamId, address indexed member);
    event DocumentViewed(uint256 docId, address viewer);
    event DocumentDownloaded(uint256 docId, address downloader);
    event DebugLog(string message);
    
    // 생성자 - 컨트랙트 배포자를 관리자로 설정
    constructor() {
        admin = msg.sender;
    }
    
    // 관리자 전용 함수를 위한 수정자
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    
    // 문서 생성 함수
    function createDocument(
        string memory _title, 
        string memory _documentHash, 
        bool _isPrivate
    ) public {
        emit DebugLog("Document creation started");
        
        // 입력값 검증
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_documentHash).length > 0, "Document hash cannot be empty");
        
        emit DebugLog("Input validation passed");
        
        // 새 문서 생성
        documents[documentCount] = Document({
            title: _title,
            documentHash: _documentHash,
            owner: msg.sender,
            isPrivate: _isPrivate,
            tags: new string[](0),
            viewCount: 0,
            downloadCount: 0,
            isEncrypted: false,
            encryptionKey: ""
        });
        
        emit DebugLog("Document struct created");
        
        // 문서 소유자에게 접근 권한 부여
        documentAccess[documentCount][msg.sender] = true;
        documentAccessList[documentCount].push(msg.sender);
        
        emit DebugLog("Access granted to owner");
        
        // 이벤트 발생
        emit DocumentCreated(documentCount, _title, msg.sender, _documentHash, _isPrivate);
        
        documentCount++;
        emit DebugLog("Document creation completed");
    }
    
    // 공유 링크 생성 함수
    function createShareLink(
        uint256 _docId,
        uint256 _expiryTime,
        bool _isPasswordProtected,
        string memory _passwordHash,
        uint256 _maxUses
    ) public returns (string memory) {
        require(_docId < documentCount, "Invalid document ID");
        require(documents[_docId].owner == msg.sender, "Not the owner");
        
        string memory linkId = generateLinkId();
        shareLinks[linkId] = ShareLink({
            linkId: linkId,
            docId: _docId,
            expiryTime: block.timestamp + _expiryTime,
            isPasswordProtected: _isPasswordProtected,
            passwordHash: _passwordHash,
            maxUses: _maxUses,
            currentUses: 0
        });
        
        emit ShareLinkCreated(linkId, _docId, _expiryTime);
        return linkId;
    }
    
    // 팀 생성 함수
    function createTeam(string memory _name) public {
        uint256 teamId = teamCount;
        teams[teamId].name = _name;
        teams[teamId].owner = msg.sender;
        teams[teamId].members.push(msg.sender);
        teams[teamId].isMember[msg.sender] = true;
        userTeams[msg.sender].push(teamId);
        teamCount++;
        emit TeamCreated(teamId, _name, msg.sender);
    }
    
    // 팀원 추가 함수
    function addTeamMember(uint256 _teamId, address _member) public {
        require(_teamId < teamCount, "Invalid team ID");
        require(teams[_teamId].owner == msg.sender, "Not the team owner");
        require(!teams[_teamId].isMember[_member], "Already a member");
        
        teams[_teamId].members.push(_member);
        teams[_teamId].isMember[_member] = true;
        userTeams[_member].push(_teamId);
        emit TeamMemberAdded(_teamId, _member);
    }
    
    // 팀원 제거 함수
    function removeTeamMember(uint256 _teamId, address _member) public {
        require(_teamId < teamCount, "Invalid team ID");
        require(teams[_teamId].owner == msg.sender, "Not the team owner");
        require(teams[_teamId].isMember[_member], "Not a member");
        require(_member != msg.sender, "Cannot remove owner");
        
        // 팀원 목록에서 제거
        for (uint i = 0; i < teams[_teamId].members.length; i++) {
            if (teams[_teamId].members[i] == _member) {
                teams[_teamId].members[i] = teams[_teamId].members[teams[_teamId].members.length - 1];
                teams[_teamId].members.pop();
                break;
            }
        }
        
        // 매핑 업데이트
        teams[_teamId].isMember[_member] = false;
        
        // 사용자의 팀 목록에서 제거
        for (uint i = 0; i < userTeams[_member].length; i++) {
            if (userTeams[_member][i] == _teamId) {
                userTeams[_member][i] = userTeams[_member][userTeams[_member].length - 1];
                userTeams[_member].pop();
                break;
            }
        }
        
        emit TeamMemberRemoved(_teamId, _member);
    }
    
    // 문서 조회 함수
    function viewDocument(uint256 _docId) public {
        require(_docId < documentCount, "Invalid document ID");
        require(canAccessDocument(_docId), "No access");
        
        documents[_docId].viewCount++;
        emit DocumentViewed(_docId, msg.sender);
    }
    
    // 문서 다운로드 함수
    function downloadDocument(uint256 _docId) public {
        require(_docId < documentCount, "Invalid document ID");
        require(canAccessDocument(_docId), "No access");
        
        documents[_docId].downloadCount++;
        emit DocumentDownloaded(_docId, msg.sender);
    }
    
    // 문서 접근 권한 확인 함수
    function canAccessDocument(uint256 _docId) public view returns (bool) {
        if (_docId >= documentCount) return false;
        
        Document storage doc = documents[_docId];
        
        // 문서 소유자는 항상 접근 가능
        if (doc.owner == msg.sender) return true;
        
        // 비공개 문서이고 접근 권한이 없는 경우
        if (doc.isPrivate && !documentAccess[_docId][msg.sender]) return false;
        
        return true;
    }
    
    // 공유 링크 접근 함수
    function accessViaShareLink(
        string memory _linkId,
        string memory _password
    ) public returns (bool) {
        ShareLink storage link = shareLinks[_linkId];
        require(link.expiryTime > block.timestamp, "Link expired");
        require(link.currentUses < link.maxUses, "Max uses reached");
        
        if (link.isPasswordProtected) {
            require(keccak256(bytes(_password)) == keccak256(bytes(link.passwordHash)), "Invalid password");
        }
        
        link.currentUses++;
        return canAccessDocument(link.docId);
    }
    
    // 링크 ID 생성 함수 (내부용)
    function generateLinkId() internal view returns (string memory) {
        return string(abi.encodePacked(
            "link_",
            uint2str(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))))
        ));
    }
    
    // uint를 string으로 변환하는 함수 (내부용)
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    // 접근 권한 부여 함수
    function grantAccess(uint256 _docId, address _user) public {
        require(_docId < documentCount, "Invalid document ID");
        require(documents[_docId].owner == msg.sender, "Not the owner");
        
        // 접근 권한 부여
        documentAccess[_docId][_user] = true;
        // 접근 권한 목록에 추가
        documentAccessList[_docId].push(_user);
        emit AccessGranted(_docId, _user);
    }
    
    // 접근 권한 해제 함수
    function revokeAccess(uint256 _docId, address _user) public {
        require(_docId < documentCount, "Invalid document ID");
        require(documents[_docId].owner == msg.sender, "Not the owner");
        
        // 접근 권한 해제
        documentAccess[_docId][_user] = false;
        // 접근 권한 목록에서 제거
        for (uint i = 0; i < documentAccessList[_docId].length; i++) {
            if (documentAccessList[_docId][i] == _user) {
                documentAccessList[_docId][i] = documentAccessList[_docId][documentAccessList[_docId].length - 1];
                documentAccessList[_docId].pop();
                break;
            }
        }
        emit AccessRevoked(_docId, _user);
    }
    
    // 모든 접근 권한 해제 함수
    function revokeAllAccess(uint256 _docId) public {
        require(_docId < documentCount, "Invalid document ID");
        require(documents[_docId].owner == msg.sender, "Not the owner");
        
        // 모든 접근 권한 해제
        for (uint i = 0; i < documentAccessList[_docId].length; i++) {
            documentAccess[_docId][documentAccessList[_docId][i]] = false;
        }
        // 접근 권한 목록 초기화
        delete documentAccessList[_docId];
    }
    
    // 접근 권한 목록 조회 함수
    function getAccessList(uint256 _docId) public view returns (address[] memory) {
        require(_docId < documentCount, "Invalid document ID");
        require(documents[_docId].owner == msg.sender, "Not the owner");
        
        return documentAccessList[_docId];
    }
    
    // 문서 조회 함수
    function getDocument(uint256 _docId) public view returns (
        string memory title,
        string memory documentHash,
        address owner,
        bool isPrivate,
        bool hasAccess
    ) {
        require(_docId < documentCount, "Invalid document ID");
        Document storage doc = documents[_docId];
        
        // 문서 소유자는 항상 접근 가능
        if (doc.owner == msg.sender) {
            return (doc.title, doc.documentHash, doc.owner, doc.isPrivate, true);
        }
        
        // 비공개 문서이고 접근 권한이 없는 경우
        if (doc.isPrivate && !documentAccess[_docId][msg.sender]) {
            return (doc.title, doc.documentHash, doc.owner, doc.isPrivate, false);
        }
        
        // 공개 문서이거나 접근 권한이 있는 경우
        return (doc.title, doc.documentHash, doc.owner, doc.isPrivate, true);
    }
    
    // 문서 삭제 함수
    function deleteDocument(uint256 _docId) public {
        require(_docId < documentCount, "Invalid document ID");
        require(documents[_docId].owner == msg.sender, "Not the document owner");
        
        // 문서 삭제
        delete documents[_docId];
        
        // 접근 권한 목록도 삭제
        delete documentAccessList[_docId];
    }
    
    // 문서 수정 함수
    function updateDocument(uint256 _docId, string memory _newTitle, bool _isPrivate) public {
        require(_docId < documentCount, "Invalid document ID");
        require(documents[_docId].owner == msg.sender, "Not the document owner");
        
        // 문서 정보 업데이트
        documents[_docId].title = _newTitle;
        documents[_docId].isPrivate = _isPrivate;
    }
    
    // 소유권 이전 함수
    function transferOwnership(uint256 _docId, address _newOwner) public {
        require(_docId < documentCount, "Invalid document ID");
        require(documents[_docId].owner == msg.sender, "Not the document owner");
        require(_newOwner != address(0), "Invalid new owner address");
        
        // 소유권 이전
        documents[_docId].owner = _newOwner;
    }
} 