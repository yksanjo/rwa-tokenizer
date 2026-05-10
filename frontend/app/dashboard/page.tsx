"use client";

import { Sidebar } from "@/components/Sidebar";
import { Header } from "@/components/Header";
import { StatsCard } from "@/components/StatsCard";
import { useRWAToken } from "@/hooks/useRWAToken";
import { formatCurrency, formatNumber } from "@/lib/utils";
import {
  DollarSign,
  TrendingUp,
  Users,
  Building2,
  ArrowUpRight,
  ArrowDownRight,
} from "lucide-react";

export default function DashboardPage() {
  const rwa = useRWAToken();
  const name = rwa.name as string | undefined;
  const symbol = rwa.symbol as string | undefined;
  const nav = rwa.nav as bigint | undefined;
  const totalShares = rwa.totalShares as bigint | undefined;
  const sharePrice = rwa.sharePrice as bigint | undefined;
  const managementFee = rwa.managementFee as bigint | undefined;

  return (
    <div className="flex min-h-screen bg-zinc-950">
      <Sidebar />
      <div className="flex-1 pl-64">
        <Header />
        <main className="p-6">
          {/* Page Header */}
          <div className="mb-8">
            <h1 className="text-2xl font-bold text-white">Dashboard</h1>
            <p className="mt-1 text-sm text-zinc-400">
              Overview of your tokenized assets
            </p>
          </div>

          {/* Stats Grid */}
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <StatsCard
              title="Total NAV"
              value={nav ? formatCurrency(nav, 0) : "$0"}
              change="+2.5%"
              isPositive={true}
              icon={DollarSign}
            />
            <StatsCard
              title="Share Price"
              value={sharePrice ? formatCurrency(sharePrice) : "$0"}
              change="+1.2%"
              isPositive={true}
              icon={TrendingUp}
            />
            <StatsCard
              title="Total Shares"
              value={totalShares ? formatNumber(Number(totalShares)) : "0"}
              change="+5.0%"
              isPositive={true}
              icon={Users}
            />
            <StatsCard
              title="Management Fee"
              value={managementFee ? `${Number(managementFee) / 100}%` : "0%"}
              icon={Building2}
            />
          </div>

          {/* Token Info */}
          <div className="mt-8 grid gap-6 lg:grid-cols-2">
            {/* Token Details */}
            <div className="rounded-xl border border-zinc-800 bg-zinc-900 p-6">
              <h2 className="text-lg font-semibold text-white mb-4">
                Token Details
              </h2>
              <div className="space-y-4">
                <div className="flex justify-between">
                  <span className="text-zinc-400">Name</span>
                  <span className="text-white font-medium">
                    {name || "Loading..."}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-zinc-400">Symbol</span>
                  <span className="text-white font-medium">
                    {symbol || "Loading..."}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-zinc-400">Asset Type</span>
                  <span className="text-white font-medium">Treasury</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-zinc-400">Status</span>
                  <span className="inline-flex items-center gap-1 text-emerald-500">
                    <span className="h-2 w-2 rounded-full bg-emerald-500" />
                    Active
                  </span>
                </div>
              </div>
            </div>

            {/* Recent Activity */}
            <div className="rounded-xl border border-zinc-800 bg-zinc-900 p-6">
              <h2 className="text-lg font-semibold text-white mb-4">
                Recent Activity
              </h2>
              <div className="space-y-4">
                {[
                  {
                    action: "NAV Updated",
                    detail: "$1,050,000.00",
                    time: "2 hours ago",
                    positive: true,
                  },
                  {
                    action: "Tokens Minted",
                    detail: "10,000 USTB",
                    time: "5 hours ago",
                    positive: true,
                  },
                  {
                    action: "Transfer",
                    detail: "1,000 USTB → 0x1234...5678",
                    time: "1 day ago",
                    positive: true,
                  },
                  {
                    action: "Fee Accrued",
                    detail: "$1,575.00",
                    time: "2 days ago",
                    positive: false,
                  },
                ].map((activity, i) => (
                  <div
                    key={i}
                    className="flex items-center justify-between rounded-lg bg-zinc-800/50 p-3"
                  >
                    <div className="flex items-center gap-3">
                      {activity.positive ? (
                        <ArrowUpRight className="h-4 w-4 text-emerald-500" />
                      ) : (
                        <ArrowDownRight className="h-4 w-4 text-red-500" />
                      )}
                      <div>
                        <p className="text-sm font-medium text-white">
                          {activity.action}
                        </p>
                        <p className="text-xs text-zinc-500">
                          {activity.detail}
                        </p>
                      </div>
                    </div>
                    <span className="text-xs text-zinc-500">
                      {activity.time}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
