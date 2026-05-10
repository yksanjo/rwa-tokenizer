# DeepSeek Prompt: Generate RWA Tokenization API

## Context
You are generating a FastAPI backend for managing tokenized real-world assets. This API serves as the bridge between traditional finance systems and blockchain.

## Requirements

Generate a complete FastAPI application with:

### 1. Authentication & Authorization
- API key authentication
- JWT-based user sessions
- Role-based access (admin, issuer, investor, viewer)
- Rate limiting per tier

### 2. Token Management Endpoints
```
POST   /api/v1/tokens          - Create new tokenized asset
GET    /api/v1/tokens          - List all tokens
GET    /api/v1/tokens/:id      - Get token details
PUT    /api/v1/tokens/:id      - Update token metadata
POST   /api/v1/tokens/:id/mint - Mint new tokens
POST   /api/v1/tokens/:id/burn - Burn tokens
```

### 3. Compliance Endpoints
```
POST   /api/v1/compliance/kyc      - Submit KYC
GET    /api/v1/compliance/status   - Check KYC status
POST   /api/v1/compliance/whitelist - Add to whitelist
POST   /api/v1/compliance/blacklist - Add to blacklist
```

### 4. Analytics Endpoints
```
GET    /api/v1/analytics/portfolio  - Portfolio overview
GET    /api/v1/analytics/yields     - Yield tracking
GET    /api/v1/analytics/transfers  - Transfer history
GET    /api/v1/analytics/nav        - NAV history
```

### 5. Web3 Integration
- Web3.py for blockchain interaction
- Event listeners for on-chain events
- Transaction status tracking
- Gas estimation

### 6. Data Models (SQLAlchemy)
- User, Token, Transfer, Compliance, NAV, Fee
- PostgreSQL database
- Alembic migrations

## Output Format
1. Complete Python files with proper structure
2. requirements.txt
3. Dockerfile
4. docker-compose.yml
5. API documentation (OpenAPI/Swagger)

## Additional Notes
- Use Python 3.11+
- Async endpoints where possible
- Comprehensive error handling
- Logging with structured format
- Redis caching for frequent queries
