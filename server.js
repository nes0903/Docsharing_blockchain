const express = require('express');
const cors = require('cors');
const multer = require('multer');
const FormData = require('form-data');
const fetch = require('node-fetch');
const app = express();
const upload = multer();

// CORS 설정 - 다른 도메인에서의 요청 허용
app.use(cors());
app.use(express.static('.'));

// IPFS API 프록시 엔드포인트 - 파일 업로드 처리
app.post('/ipfs/add', upload.single('file'), async (req, res) => {
    try {
        // FormData 생성 및 파일 추가
        const formData = new FormData();
        formData.append('file', req.file.buffer, {
            filename: req.file.originalname,
            contentType: req.file.mimetype
        });

        // IPFS API 호출
        const response = await fetch('http://127.0.0.1:5001/api/v0/add', {
            method: 'POST',
            body: formData
        });

        // 결과 반환
        const result = await response.json();
        res.json(result);
    } catch (error) {
        console.error('IPFS 업로드 실패:', error);
        res.status(500).json({ error: 'IPFS 업로드 실패' });
    }
});

// IPFS 파일 다운로드 엔드포인트
app.get('/ipfs/cat/:hash', async (req, res) => {
    try {
        // IPFS API 호출
        const response = await fetch(`http://127.0.0.1:5001/api/v0/cat?arg=${req.params.hash}`);
        if (!response.ok) throw new Error('IPFS 파일 다운로드 실패');
        if (!response.body) throw new Error('IPFS 응답에 body가 없음');

        // 응답 헤더 설정
        res.setHeader('Content-Type', 'application/octet-stream');
        res.setHeader('Content-Disposition', 'attachment');

        // 파일 스트림을 클라이언트로 전송
        response.body.pipe(res);
    } catch (error) {
        console.error('IPFS 파일 다운로드 실패:', error);
        res.status(500).send('파일 다운로드 실패');
    }
});

// 서버 포트 설정 및 시작
const PORT = 8000;
app.listen(PORT, () => {
    console.log(`서버가 http://localhost:${PORT} 에서 실행 중입니다.`);
}); 