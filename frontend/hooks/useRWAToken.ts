"use client";

import { useReadContract, useWriteContract, useWatchContractEvent } from "wagmi";
import { RWA_TOKEN_ABI, getContractAddress } from "@/lib/contracts";
import { useChainId } from "wagmi";

export function useRWAToken() {
  const chainId = useChainId();
  const address = getContractAddress(chainId);

  // Read functions
  const { data: name } = useReadContract({
    address,
    abi: RWA_TOKEN_ABI,
    functionName: "name",
  });

  const { data: symbol } = useReadContract({
    address,
    abi: RWA_TOKEN_ABI,
    functionName: "symbol",
  });

  const { data: nav } = useReadContract({
    address,
    abi: RWA_TOKEN_ABI,
    functionName: "nav",
  });

  const { data: totalShares } = useReadContract({
    address,
    abi: RWA_TOKEN_ABI,
    functionName: "totalShares",
  });

  const { data: sharePrice } = useReadContract({
    address,
    abi: RWA_TOKEN_ABI,
    functionName: "getSharePrice",
  });

  const { data: managementFee } = useReadContract({
    address,
    abi: RWA_TOKEN_ABI,
    functionName: "managementFee",
  });

  // Write functions
  const { writeContract: mint } = useWriteContract();
  const { writeContract: burn } = useWriteContract();
  const { writeContract: updateNAV } = useWriteContract();
  const { writeContract: whitelist } = useWriteContract();

  // Watch events
  useWatchContractEvent({
    address,
    abi: RWA_TOKEN_ABI,
    eventName: "NAVUpdated",
    onLogs(logs) {
      console.log("NAV Updated:", logs);
    },
  });

  return {
    // State
    name,
    symbol,
    nav,
    totalShares,
    sharePrice,
    managementFee,
    
    // Actions
    mint: (to: `0x${string}`, amount: bigint) =>
      mint({ address, abi: RWA_TOKEN_ABI, functionName: "mint", args: [to, amount] }),
    burn: (from: `0x${string}`, amount: bigint) =>
      burn({ address, abi: RWA_TOKEN_ABI, functionName: "burn", args: [from, amount] }),
    updateNAV: (nav: bigint) =>
      updateNAV({ address, abi: RWA_TOKEN_ABI, functionName: "updateNAV", args: [nav] }),
    whitelist: (account: `0x${string}`, claim: `0x${string}`) =>
      whitelist({ address, abi: RWA_TOKEN_ABI, functionName: "whitelistAddress", args: [account, claim] }),
  };
}
