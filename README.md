# Docsharing_blockchain
Documents sharing system based on ETH process
Decentralized Document Sharing dApp (IPFS + Ethereum 기반 문서 공유 시스템)

◆ 프로젝트 개요

이 프로젝트는 **IPFS(InterPlanetary File System)** 와 **Ethereum 스마트 컨트랙트**를 기반으로 하는 **탈중앙화 문서 공유 및 접근 제어 시스템**입니다. 문서는 IPFS에 저장되며, 파일 메타데이터 및 접근 권한 정보는 스마트 컨트랙트에 저장되어 중앙 서버 없이도 **투명하고 검열 불가능한 공유 기능**을 제공합니다.

---

◆ 주요 기능

- 문서 등록 (IPFS 업로드 + 온체인 메타데이터 저장)

- 문서 접근 권한 부여/회수

- 문서 목록 검색, 필터, 정렬

- 문서 미리보기 (TXT, PDF, IMG 등)

- 소유권 이전 및 삭제 기능

- IPFS를 통한 파일 다운로드

---

◆ 기술 스택

| 영역            | 기술                         |
|-----------------|------------------------------|
| 스마트 컨트랙트 | Solidity, Remix IDE          |
| 배포/테스트     | Ganache, MetaMask            |
| 프론트엔드      | HTML/CSS/JavaScript, Web3.js |
| 백엔드(Proxy)   | Node.js, Express, Multer     |
| 저장소          | IPFS (로컬 또는 Infura API)  |

---

◆ 시스템 구조 요약

```text
[사용자]
   ↓
[Web UI] ──▶ [Proxy 서버] ──▶ [IPFS]
         └─▶ [Smart Contract (Ethereum)]
