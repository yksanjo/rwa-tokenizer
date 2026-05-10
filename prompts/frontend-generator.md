# DeepSeek Prompt: Generate RWA Dashboard Frontend

## Context
You are generating a Next.js 14 dashboard for managing and tracking tokenized real-world assets. The dashboard serves institutional investors and asset managers.

## Requirements

Generate a complete Next.js 14 application with:

### 1. Pages
```
/                     - Landing page with market overview
/dashboard            - Main dashboard with portfolio summary
/dashboard/tokens     - Token management (create, mint, burn)
/dashboard/portfolio  - Portfolio tracking & analytics
/dashboard/compliance - KYC/AML management
/dashboard/settings   - User settings & API keys
/tokens/:id           - Individual token detail page
```

### 2. Core Components
- **Layout**: Sidebar navigation, header with wallet connect, responsive
- **Charts**: Portfolio allocation, NAV history, yield curves (Recharts)
- **Tables**: Token list, transfer history, compliance queue
- **Forms**: Token creation, mint/burn, KYC submission
- **Modals**: Transaction confirmation, error handling
- **Wallet**: Connect button (RainbowKit/Wagmi), balance display

### 3. Web3 Integration
- Wagmi hooks for blockchain interaction
- RainbowKit for wallet connection
- viem for ethers operations
- Contract interaction via generated hooks

### 4. State Management
- React Query for server state
- Wagmi for blockchain state
- Zustand for UI state

### 5. Styling
- Tailwind CSS
- shadcn/ui components
- Dark/light mode
- Responsive design

### 6. Features
- Real-time price feeds via WebSocket
- Transaction history with status tracking
- Export data (CSV, PDF)
- Multi-language support (i18n)
- Role-based UI rendering

## Tech Stack
- Next.js 14 (App Router)
- TypeScript
- Tailwind CSS
- shadcn/ui
- Wagmi + RainbowKit
- React Query
- Recharts

## Output Format
1. Complete file structure with all components
2. package.json with dependencies
3. Configuration files (tailwind, next.config, tsconfig)
4. Environment variables template
5. Deployment configuration (Vercel)

## Additional Notes
- SEO optimized
- Accessibility (a11y) compliant
- Performance optimized (lazy loading, code splitting)
- Error boundaries for each section
