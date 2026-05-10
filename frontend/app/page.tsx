"use client";

import Link from "next/link";
import { Wallet, ArrowRight, Shield, Zap, Globe } from "lucide-react";

export default function HomePage() {
  return (
    <div className="min-h-screen bg-zinc-950">
      {/* Navigation */}
      <nav className="flex items-center justify-between border-b border-zinc-800 px-6 py-4">
        <div className="flex items-center gap-2">
          <Wallet className="h-6 w-6 text-violet-500" />
          <span className="text-lg font-bold text-white">RWA Tokenizer</span>
        </div>
        <div className="flex items-center gap-4">
          <Link
            href="/dashboard"
            className="rounded-lg bg-violet-600 px-4 py-2 text-sm font-medium text-white hover:bg-violet-700 transition-colors"
          >
            Launch Dashboard
          </Link>
        </div>
      </nav>

      {/* Hero */}
      <main className="mx-auto max-w-6xl px-6 py-20">
        <div className="text-center">
          <h1 className="text-5xl font-bold tracking-tight text-white sm:text-6xl">
            Tokenize Real-World Assets
            <span className="block text-violet-500">at the Speed of AI</span>
          </h1>
          <p className="mt-6 text-lg leading-8 text-zinc-400 max-w-2xl mx-auto">
            Built for solo developers. Ship compliant tokenized assets in days, not months.
            Powered by DeepSeek AI for rapid iteration.
          </p>
          <div className="mt-10 flex items-center justify-center gap-4">
            <Link
              href="/dashboard"
              className="rounded-lg bg-violet-600 px-8 py-3 text-base font-semibold text-white hover:bg-violet-700 transition-colors flex items-center gap-2"
            >
              Enter Dashboard
              <ArrowRight className="h-5 w-5" />
            </Link>
          </div>
        </div>

        {/* Features */}
        <div className="mt-32 grid gap-8 sm:grid-cols-3">
          <div className="rounded-xl border border-zinc-800 bg-zinc-900 p-6">
            <Shield className="h-8 w-8 text-violet-500 mb-4" />
            <h3 className="text-lg font-semibold text-white">Compliant by Default</h3>
            <p className="mt-2 text-sm text-zinc-400">
              Built-in KYC/AML whitelist, transfer restrictions, and role-based access control.
            </p>
          </div>
          <div className="rounded-xl border border-zinc-800 bg-zinc-900 p-6">
            <Zap className="h-8 w-8 text-violet-500 mb-4" />
            <h3 className="text-lg font-semibold text-white">AI-Accelerated</h3>
            <p className="mt-2 text-sm text-zinc-400">
              DeepSeek generates contracts, tests, and frontend code. You ship faster.
            </p>
          </div>
          <div className="rounded-xl border border-zinc-800 bg-zinc-900 p-6">
            <Globe className="h-8 w-8 text-violet-500 mb-4" />
            <h3 className="text-lg font-semibold text-white">Multi-Chain</h3>
            <p className="mt-2 text-sm text-zinc-400">
              Deploy to Ethereum, Polygon, Arbitrum, Optimism from one codebase.
            </p>
          </div>
        </div>

        {/* Stats */}
        <div className="mt-20 rounded-xl border border-zinc-800 bg-zinc-900 p-8">
          <div className="grid gap-8 sm:grid-cols-3 text-center">
            <div>
              <p className="text-3xl font-bold text-white">$30T+</p>
              <p className="text-sm text-zinc-400">Tokenizable Asset Market</p>
            </div>
            <div>
              <p className="text-3xl font-bold text-white">3-5 Days</p>
              <p className="text-sm text-zinc-400">Ship Time (Solo Dev)</p>
            </div>
            <div>
              <p className="text-3xl font-bold text-white">100%</p>
              <p className="text-sm text-zinc-400">On-Chain Compliance</p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
