import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { mainnet, sepolia, polygon, arbitrum, optimism } from "wagmi/chains";

export const config = getDefaultConfig({
  appName: "RWA Tokenizer",
  projectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID || "",
  chains: [mainnet, sepolia, polygon, arbitrum, optimism],
  ssr: true,
});
