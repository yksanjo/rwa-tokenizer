"use client";

import { cn } from "@/lib/utils";
import { LucideIcon, TrendingUp, TrendingDown } from "lucide-react";

interface StatsCardProps {
  title: string;
  value: string;
  change?: string;
  isPositive?: boolean;
  icon: LucideIcon;
  className?: string;
}

export function StatsCard({
  title,
  value,
  change,
  isPositive,
  icon: Icon,
  className,
}: StatsCardProps) {
  return (
    <div
      className={cn(
        "rounded-xl border border-zinc-800 bg-zinc-900 p-6 transition-colors hover:border-zinc-700",
        className
      )}
    >
      <div className="flex items-center justify-between">
        <p className="text-sm font-medium text-zinc-400">{title}</p>
        <Icon className="h-5 w-5 text-zinc-500" />
      </div>
      <div className="mt-3">
        <p className="text-2xl font-bold text-white">{value}</p>
        {change && (
          <div className="mt-1 flex items-center gap-1">
            {isPositive ? (
              <TrendingUp className="h-4 w-4 text-emerald-500" />
            ) : (
              <TrendingDown className="h-4 w-4 text-red-500" />
            )}
            <span
              className={cn(
                "text-sm font-medium",
                isPositive ? "text-emerald-500" : "text-red-500"
              )}
            >
              {change}
            </span>
          </div>
        )}
      </div>
    </div>
  );
}
