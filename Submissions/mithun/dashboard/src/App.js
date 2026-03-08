import React, { useMemo, useState, useEffect, useRef, useCallback } from 'react';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell,
  PieChart, Pie
} from 'recharts';
import { bbCreateAssistant, bbCreateThread, bbSendMessage } from './backboard';

// ─── Raw Donation Entries (75 realistic entries, last 7 days) ────────────────

const RAW_DONATIONS = [
  // ── Saturday Mar 7 (today) — 15 entries, heaviest day ──
  { causeId: 'hamilton-food-share', binLocation: 'Fortinos — Main St',   amount: 25,  meals: 6,  city: 'Hamilton',  timestamp: '2026-03-07T09:12:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Walmart — Rymal Rd',   amount: 10,  meals: 2,  city: 'Hamilton',  timestamp: '2026-03-07T09:45:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Loblaws — King St',    amount: 25,  meals: 6,  city: 'Hamilton',  timestamp: '2026-03-07T10:03:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Fortinos — Main St',   amount: 5,   meals: 1,  city: 'Hamilton',  timestamp: '2026-03-07T10:30:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Walmart — Rymal Rd',   amount: 10,  meals: 2,  city: 'Hamilton',  timestamp: '2026-03-07T11:15:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Fortinos — Main St',   amount: 25,  meals: 6,  city: 'Hamilton',  timestamp: '2026-03-07T12:00:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Loblaws — King St',    amount: 10,  meals: 2,  city: 'Hamilton',  timestamp: '2026-03-07T13:22:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'Metro — Yonge St',     amount: 25,  meals: 6,  city: 'Toronto',   timestamp: '2026-03-07T09:30:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'No Frills — Queen St', amount: 10,  meals: 2,  city: 'Toronto',   timestamp: '2026-03-07T10:50:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'Loblaws — Dundas Ave', amount: 5,   meals: 1,  city: 'Toronto',   timestamp: '2026-03-07T11:40:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'Metro — Yonge St',     amount: 25,  meals: 6,  city: 'Toronto',   timestamp: '2026-03-07T13:05:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'Save-On — Broadway',   amount: 10,  meals: 2,  city: 'Vancouver', timestamp: '2026-03-07T10:00:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'No Frills — Kingsway', amount: 25,  meals: 6,  city: 'Vancouver', timestamp: '2026-03-07T11:20:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'Superstore — Grandview', amount: 5, meals: 1,  city: 'Vancouver', timestamp: '2026-03-07T12:15:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'Save-On — Broadway',   amount: 10,  meals: 2,  city: 'Vancouver', timestamp: '2026-03-07T13:45:00Z' },

  // ── Friday Mar 6 — 13 entries ──
  { causeId: 'hamilton-food-share', binLocation: 'Fortinos — Main St',   amount: 10,  meals: 2,  city: 'Hamilton',  timestamp: '2026-03-06T08:20:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Walmart — Rymal Rd',   amount: 25,  meals: 6,  city: 'Hamilton',  timestamp: '2026-03-06T09:55:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Loblaws — King St',    amount: 5,   meals: 1,  city: 'Hamilton',  timestamp: '2026-03-06T11:30:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Fortinos — Main St',   amount: 25,  meals: 6,  city: 'Hamilton',  timestamp: '2026-03-06T14:10:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Walmart — Rymal Rd',   amount: 10,  meals: 2,  city: 'Hamilton',  timestamp: '2026-03-06T16:45:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'No Frills — Queen St', amount: 25,  meals: 6,  city: 'Toronto',   timestamp: '2026-03-06T08:50:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'Loblaws — Dundas Ave', amount: 10,  meals: 2,  city: 'Toronto',   timestamp: '2026-03-06T10:15:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'Metro — Yonge St',     amount: 5,   meals: 1,  city: 'Toronto',   timestamp: '2026-03-06T13:30:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'No Frills — Queen St', amount: 25,  meals: 6,  city: 'Toronto',   timestamp: '2026-03-06T15:20:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'Save-On — Broadway',   amount: 25,  meals: 6,  city: 'Vancouver', timestamp: '2026-03-06T09:10:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'No Frills — Kingsway', amount: 10,  meals: 2,  city: 'Vancouver', timestamp: '2026-03-06T12:00:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'Superstore — Grandview', amount: 5, meals: 1,  city: 'Vancouver', timestamp: '2026-03-06T14:40:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'Save-On — Broadway',   amount: 10,  meals: 2,  city: 'Vancouver', timestamp: '2026-03-06T17:00:00Z' },

  // ── Thursday Mar 5 — 11 entries ──
  { causeId: 'hamilton-food-share', binLocation: 'Walmart — Rymal Rd',   amount: 5,   meals: 1,  city: 'Hamilton',  timestamp: '2026-03-05T07:45:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Fortinos — Main St',   amount: 10,  meals: 2,  city: 'Hamilton',  timestamp: '2026-03-05T09:30:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Loblaws — King St',    amount: 25,  meals: 6,  city: 'Hamilton',  timestamp: '2026-03-05T12:10:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Fortinos — Main St',   amount: 10,  meals: 2,  city: 'Hamilton',  timestamp: '2026-03-05T15:00:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'Metro — Yonge St',     amount: 10,  meals: 2,  city: 'Toronto',   timestamp: '2026-03-05T08:20:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'Loblaws — Dundas Ave', amount: 25,  meals: 6,  city: 'Toronto',   timestamp: '2026-03-05T11:00:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'No Frills — Queen St', amount: 5,   meals: 1,  city: 'Toronto',   timestamp: '2026-03-05T14:30:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'No Frills — Kingsway', amount: 25,  meals: 6,  city: 'Vancouver', timestamp: '2026-03-05T09:00:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'Superstore — Grandview', amount: 10, meals: 2, city: 'Vancouver', timestamp: '2026-03-05T12:45:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'Save-On — Broadway',   amount: 5,   meals: 1,  city: 'Vancouver', timestamp: '2026-03-05T16:10:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Walmart — Rymal Rd',   amount: 25,  meals: 6,  city: 'Hamilton',  timestamp: '2026-03-05T17:30:00Z' },

  // ── Wednesday Mar 4 — 10 entries ──
  { causeId: 'hamilton-food-share', binLocation: 'Fortinos — Main St',   amount: 25,  meals: 6,  city: 'Hamilton',  timestamp: '2026-03-04T08:00:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Loblaws — King St',    amount: 10,  meals: 2,  city: 'Hamilton',  timestamp: '2026-03-04T10:20:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Walmart — Rymal Rd',   amount: 5,   meals: 1,  city: 'Hamilton',  timestamp: '2026-03-04T13:15:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Fortinos — Main St',   amount: 10,  meals: 2,  city: 'Hamilton',  timestamp: '2026-03-04T16:40:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'Loblaws — Dundas Ave', amount: 10,  meals: 2,  city: 'Toronto',   timestamp: '2026-03-04T09:10:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'Metro — Yonge St',     amount: 25,  meals: 6,  city: 'Toronto',   timestamp: '2026-03-04T12:30:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'No Frills — Queen St', amount: 5,   meals: 1,  city: 'Toronto',   timestamp: '2026-03-04T15:00:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'Save-On — Broadway',   amount: 10,  meals: 2,  city: 'Vancouver', timestamp: '2026-03-04T08:45:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'No Frills — Kingsway', amount: 25,  meals: 6,  city: 'Vancouver', timestamp: '2026-03-04T11:55:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'Superstore — Grandview', amount: 5, meals: 1,  city: 'Vancouver', timestamp: '2026-03-04T14:20:00Z' },

  // ── Tuesday Mar 3 — 9 entries ──
  { causeId: 'hamilton-food-share', binLocation: 'Loblaws — King St',    amount: 10,  meals: 2,  city: 'Hamilton',  timestamp: '2026-03-03T08:30:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Fortinos — Main St',   amount: 5,   meals: 1,  city: 'Hamilton',  timestamp: '2026-03-03T11:00:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Walmart — Rymal Rd',   amount: 25,  meals: 6,  city: 'Hamilton',  timestamp: '2026-03-03T14:15:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'Metro — Yonge St',     amount: 10,  meals: 2,  city: 'Toronto',   timestamp: '2026-03-03T09:20:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'Loblaws — Dundas Ave', amount: 5,   meals: 1,  city: 'Toronto',   timestamp: '2026-03-03T12:50:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'No Frills — Queen St', amount: 25,  meals: 6,  city: 'Toronto',   timestamp: '2026-03-03T16:00:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'Superstore — Grandview', amount: 10, meals: 2, city: 'Vancouver', timestamp: '2026-03-03T08:10:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'Save-On — Broadway',   amount: 25,  meals: 6,  city: 'Vancouver', timestamp: '2026-03-03T11:30:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'No Frills — Kingsway', amount: 5,   meals: 1,  city: 'Vancouver', timestamp: '2026-03-03T15:45:00Z' },

  // ── Monday Mar 2 — 9 entries ──
  { causeId: 'hamilton-food-share', binLocation: 'Fortinos — Main St',   amount: 10,  meals: 2,  city: 'Hamilton',  timestamp: '2026-03-02T07:50:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Walmart — Rymal Rd',   amount: 10,  meals: 2,  city: 'Hamilton',  timestamp: '2026-03-02T10:30:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Loblaws — King St',    amount: 25,  meals: 6,  city: 'Hamilton',  timestamp: '2026-03-02T13:40:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'No Frills — Queen St', amount: 10,  meals: 2,  city: 'Toronto',   timestamp: '2026-03-02T08:15:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'Metro — Yonge St',     amount: 5,   meals: 1,  city: 'Toronto',   timestamp: '2026-03-02T12:00:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'Loblaws — Dundas Ave', amount: 25,  meals: 6,  city: 'Toronto',   timestamp: '2026-03-02T14:50:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'Save-On — Broadway',   amount: 5,   meals: 1,  city: 'Vancouver', timestamp: '2026-03-02T09:25:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'No Frills — Kingsway', amount: 10,  meals: 2,  city: 'Vancouver', timestamp: '2026-03-02T11:10:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'Superstore — Grandview', amount: 25, meals: 6, city: 'Vancouver', timestamp: '2026-03-02T15:30:00Z' },

  // ── Sunday Mar 1 — 8 entries (weekend) ──
  { causeId: 'hamilton-food-share', binLocation: 'Fortinos — Main St',   amount: 25,  meals: 6,  city: 'Hamilton',  timestamp: '2026-03-01T10:00:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Loblaws — King St',    amount: 10,  meals: 2,  city: 'Hamilton',  timestamp: '2026-03-01T12:30:00Z' },
  { causeId: 'hamilton-food-share', binLocation: 'Walmart — Rymal Rd',   amount: 5,   meals: 1,  city: 'Hamilton',  timestamp: '2026-03-01T14:45:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'Metro — Yonge St',     amount: 10,  meals: 2,  city: 'Toronto',   timestamp: '2026-03-01T09:30:00Z' },
  { causeId: 'toronto-daily-bread', binLocation: 'Loblaws — Dundas Ave', amount: 25,  meals: 6,  city: 'Toronto',   timestamp: '2026-03-01T13:00:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'No Frills — Kingsway', amount: 10,  meals: 2,  city: 'Vancouver', timestamp: '2026-03-01T10:20:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'Save-On — Broadway',   amount: 5,   meals: 1,  city: 'Vancouver', timestamp: '2026-03-01T11:50:00Z' },
  { causeId: 'vancouver-food-bank', binLocation: 'Superstore — Grandview', amount: 25, meals: 6, city: 'Vancouver', timestamp: '2026-03-01T15:15:00Z' },
];

const ACTIVE_CAUSE = 'hamilton-food-share';
const CHARITY = { name: 'Hamilton Food Share', city: 'Hamilton, ON' };
const WEEKLY_GOAL_TARGET = 1000;
const DAY_LABELS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

// ─── Aggregation ─────────────────────────────────────────────────────────────

function timeAgo(ts) {
  const diff = Date.now() - new Date(ts).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins} min ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs} hr ago`;
  return `${Math.floor(hrs / 24)}d ago`;
}

function aggregate(entries, causeId) {
  const causeDonations = entries.filter((e) => e.causeId === causeId);

  const now = new Date();
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const weekStart = new Date(todayStart.getTime() - 6 * 86400000);

  const todayEntries = causeDonations.filter((d) => new Date(d.timestamp) >= todayStart);
  const weekEntries = causeDonations.filter((d) => new Date(d.timestamp) >= weekStart);

  const mealsToday = todayEntries.reduce((s, d) => s + d.meals, 0);
  const dollarsToday = todayEntries.reduce((s, d) => s + d.amount, 0);
  const donationsToday = todayEntries.length;
  const avgDonation = donationsToday > 0 ? +(dollarsToday / donationsToday).toFixed(2) : 0;

  const weeklyMeals = weekEntries.reduce((s, d) => s + d.meals, 0);

  const stats = { mealsToday, dollarsToday, donationsToday, avgDonation };
  const weeklyGoal = { current: weeklyMeals, target: WEEKLY_GOAL_TARGET };

  const sorted = [...causeDonations].sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
  const feed = sorted.slice(0, 10).map((d, i) => ({
    id: i + 1,
    timeAgo: timeAgo(d.timestamp),
    amount: d.amount,
    meals: d.meals,
    bin: d.binLocation,
  }));

  const binMap = {};
  weekEntries.forEach((d) => {
    if (!binMap[d.binLocation]) binMap[d.binLocation] = { name: d.binLocation, donations: 0, dollars: 0 };
    binMap[d.binLocation].donations++;
    binMap[d.binLocation].dollars += d.amount;
  });
  const bins = Object.values(binMap)
    .sort((a, b) => b.dollars - a.dollars)
    .map((b, i) => ({ ...b, change: +([ 12.3, 8.7, -2.1 ][i] ?? 0) }));

  const trendMap = {};
  for (let i = 6; i >= 0; i--) {
    const d = new Date(todayStart.getTime() - i * 86400000);
    trendMap[DAY_LABELS[d.getDay()]] = 0;
  }
  weekEntries.forEach((d) => {
    const label = DAY_LABELS[new Date(d.timestamp).getDay()];
    if (label in trendMap) trendMap[label] += d.meals;
  });
  const weeklyTrend = Object.entries(trendMap).map(([day, meals]) => ({ day, meals }));

  return { stats, weeklyGoal, feed, bins, weeklyTrend };
}

// ─── Circular Progress Ring ──────────────────────────────────────────────────

function GoalRing({ weeklyGoal }) {
  const pct = weeklyGoal.target > 0 ? (weeklyGoal.current / weeklyGoal.target) * 100 : 0;
  const ringData = [
    { name: 'done', value: Math.min(pct, 100) },
    { name: 'left', value: Math.max(100 - pct, 0) },
  ];

  return (
    <div className="card goal-ring-card">
      <div className="goal-ring-header">
        <span className="section-label">Weekly Goal</span>
        <span className="goal-pill">{weeklyGoal.current.toLocaleString()} / {weeklyGoal.target.toLocaleString()}</span>
      </div>
      <div className="goal-ring-body">
        <div className="ring-wrapper">
          <PieChart width={160} height={160}>
            <Pie
              data={ringData}
              cx={75} cy={75}
              innerRadius={52} outerRadius={68}
              startAngle={90} endAngle={-270}
              dataKey="value" stroke="none"
            >
              <Cell fill="#2E7D32" />
              <Cell fill="#2a2a2a" />
            </Pie>
          </PieChart>
          <div className="ring-center">
            <span className="ring-pct">{Math.round(pct)}%</span>
            <span className="ring-sub">complete</span>
          </div>
        </div>
        <div className="ring-stats">
          <div className="ring-stat-item">
            <span className="ring-stat-val">{Math.max(weeklyGoal.target - weeklyGoal.current, 0).toLocaleString()}</span>
            <span className="ring-stat-lbl">meals to go</span>
          </div>
          <div className="ring-stat-item">
            <span className="ring-stat-val">7 days</span>
            <span className="ring-stat-lbl">cycle length</span>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Header ──────────────────────────────────────────────────────────────────

function Header() {
  return (
    <header className="header">
      <div className="header-left">
        <div className="logo">
          <span className="logo-text">Flourish</span>
        </div>
        <div className="header-divider" />
        <div className="header-info">
          <h1 className="charity-name">{CHARITY.name}</h1>
          <span className="charity-city">{CHARITY.city}</span>
        </div>
      </div>
      <div className="header-right">
        <div className="powered-badge">Powered by GiveClip</div>
      </div>
    </header>
  );
}

// ─── Stat Cards ──────────────────────────────────────────────────────────────

function StatCard({ label, value, sub, accent }) {
  return (
    <div className="stat-card" style={{ '--accent': accent }}>
      <div className="stat-card-top">
        <span className="stat-label">{label}</span>
      </div>
      <div className="stat-card-bottom">
        <span className="stat-value">{value}</span>
        {sub && <span className="stat-change positive">↑ {sub}</span>}
      </div>
    </div>
  );
}

function StatsRow({ stats }) {
  return (
    <div className="stats-row">
      <StatCard label="Meals Funded Today" value={stats.mealsToday.toLocaleString()} accent="#2E7D32" />
      <StatCard label="Dollars Raised Today" value={`$${stats.dollarsToday.toLocaleString()}`} accent="#4CAF50" />
      <StatCard label="Donations Today" value={stats.donationsToday} accent="#66BB6A" />
      <StatCard label="Avg. Donation" value={`$${stats.avgDonation}`} accent="#81C784" />
    </div>
  );
}

// ─── Live Donation Feed ──────────────────────────────────────────────────────

function DonationFeed({ feed }) {
  return (
    <div className="card feed-card">
      <div className="card-header-row">
        <h2 className="section-label">
          <span className="pulse-dot" />
          Live Donations
        </h2>
        <span className="card-header-sub">{feed.length} recent</span>
      </div>
      <div className="feed-list">
        {feed.map((d) => (
          <div className="feed-row" key={d.id}>
            <div className="feed-left">
              <span className="feed-amount">${d.amount}</span>
              <span className="feed-detail">{d.meals} meals</span>
            </div>
            <div className="feed-right">
              <span className="feed-bin">{d.bin}</span>
              <span className="feed-time">{d.timeAgo}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Bin Performance ─────────────────────────────────────────────────────────

function BinPerformance({ bins }) {
  const maxDollars = Math.max(...bins.map((b) => b.dollars), 1);

  return (
    <div className="card">
      <div className="card-header-row">
        <h2 className="section-label">Bin Performance</h2>
        <span className="card-header-sub">{bins.length} locations</span>
      </div>
      <div className="bin-list">
        {bins.map((bin) => (
          <div className="bin-card" key={bin.name}>
            <div className="bin-card-top">
              <span className="bin-name">{bin.name}</span>
              <span className={`bin-change ${bin.change >= 0 ? 'positive' : 'negative'}`}>
                {bin.change >= 0 ? '↑' : '↓'} {Math.abs(bin.change)}%
              </span>
            </div>
            <div className="bin-card-stats">
              <div className="bin-metric">
                <span className="bin-metric-val">{bin.donations}</span>
                <span className="bin-metric-lbl">donations</span>
              </div>
              <div className="bin-metric">
                <span className="bin-metric-val">${bin.dollars.toLocaleString()}</span>
                <span className="bin-metric-lbl">raised</span>
              </div>
            </div>
            <div className="bin-bar-track">
              <div className="bin-bar-fill" style={{ width: `${(bin.dollars / maxDollars) * 100}%` }} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Weekly Trend Chart ──────────────────────────────────────────────────────

function CustomTooltip({ active, payload, label }) {
  if (!active || !payload || !payload.length) return null;
  return (
    <div className="chart-tooltip">
      <p className="chart-tooltip-label">{label}</p>
      <p className="chart-tooltip-value">{payload[0].value} meals</p>
    </div>
  );
}

function WeeklyTrendChart({ weeklyTrend }) {
  const totalMeals = weeklyTrend.reduce((sum, d) => sum + d.meals, 0);
  const maxIdx = weeklyTrend.reduce((mi, d, i, arr) => d.meals > arr[mi].meals ? i : mi, 0);

  return (
    <div className="card">
      <div className="card-header-row">
        <div>
          <h2 className="section-label">Weekly Trend</h2>
          <span className="card-header-sub">{totalMeals.toLocaleString()} meals this week</span>
        </div>
      </div>
      <div className="chart-container">
        <ResponsiveContainer width="100%" height={240}>
          <BarChart data={weeklyTrend} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#2a2a2a" vertical={false} />
            <XAxis dataKey="day" stroke="#666" tick={{ fontSize: 12, fill: '#888' }} axisLine={false} tickLine={false} />
            <YAxis stroke="#666" tick={{ fontSize: 12, fill: '#888' }} axisLine={false} tickLine={false} />
            <Tooltip content={<CustomTooltip />} cursor={{ fill: 'rgba(46,125,50,0.08)' }} />
            <Bar dataKey="meals" radius={[8, 8, 0, 0]} barSize={36}>
              {weeklyTrend.map((entry, index) => (
                <Cell key={index} fill={index === maxIdx ? '#4CAF50' : '#2E7D32'} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}

// ─── AI Chat Panel ───────────────────────────────────────────────────────────

const SYSTEM_PROMPT = `You are a performance analyst for GiveClip, a donation platform for Canadian food banks. You help charity coordinators understand how their donation bins are performing. You have access to donation data including bin locations, amounts, meals funded, cities, and timestamps. Answer questions conversationally and give actionable recommendations. Be concise, warm, and data-driven.`;

const STARTERS = [
  'Which bin performed best this week?',
  'How does this week compare to last week?',
  'Write a donor update for our newsletter',
];

const STORAGE_KEYS = {
  assistantId: 'giveclip-assistant-id',
  threadId: 'giveclip-thread-id',
  messages: 'giveclip-chat-messages',
};

function ChatPanel({ data, onClose }) {
  const [messages, setMessages] = useState(() => {
    try { return JSON.parse(localStorage.getItem(STORAGE_KEYS.messages)) || []; }
    catch { return []; }
  });
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [ready, setReady] = useState(false);
  const threadRef = useRef(null);
  const bottomRef = useRef(null);

  useEffect(() => {
    let cancelled = false;
    async function init() {
      try {
        let aId = localStorage.getItem(STORAGE_KEYS.assistantId);
        if (!aId) {
          const a = await bbCreateAssistant('GiveClip Analyst', SYSTEM_PROMPT);
          aId = a.assistant_id;
          localStorage.setItem(STORAGE_KEYS.assistantId, aId);
        }
        let tId = localStorage.getItem(STORAGE_KEYS.threadId);
        if (!tId) {
          const t = await bbCreateThread(aId);
          tId = t.thread_id;
          localStorage.setItem(STORAGE_KEYS.threadId, tId);
        }
        if (!cancelled) {
          threadRef.current = tId;
          setReady(true);
        }
      } catch (err) {
        console.error('Backboard init:', err);
        if (!cancelled) setReady(true);
      }
    }
    init();
    return () => { cancelled = true; };
  }, []);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, loading]);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEYS.messages, JSON.stringify(messages));
  }, [messages]);

  const buildContext = useCallback(() => {
    const { stats, weeklyGoal, bins, weeklyTrend } = data;
    return [
      `[DONATION DATA — ${CHARITY.name}]`,
      `Today: ${stats.mealsToday} meals, $${stats.dollarsToday} raised, ${stats.donationsToday} donations, avg $${stats.avgDonation}`,
      `Weekly goal: ${weeklyGoal.current}/${weeklyGoal.target} meals (${Math.round((weeklyGoal.current / weeklyGoal.target) * 100)}%)`,
      'Bin performance this week:',
      ...bins.map(b => `  ${b.name}: ${b.donations} donations, $${b.dollars}`),
      `7-day trend (meals): ${weeklyTrend.map(d => `${d.day} ${d.meals}`).join(', ')}`,
    ].join('\n');
  }, [data]);

  const handleSend = useCallback(async (text) => {
    const msg = (text || '').trim();
    if (!msg || !threadRef.current || loading) return;

    setMessages(prev => [...prev, { role: 'user', content: msg }]);
    setInput('');
    setLoading(true);

    try {
      const context = buildContext();
      const result = await bbSendMessage(threadRef.current, `${context}\n\n[USER QUESTION]\n${msg}`);
      setMessages(prev => [...prev, { role: 'assistant', content: result.content }]);
    } catch (err) {
      console.error('Send error:', err);
      setMessages(prev => [...prev, { role: 'assistant', content: 'Sorry, something went wrong. Please try again.' }]);
    } finally {
      setLoading(false);
    }
  }, [loading, buildContext]);

  return (
    <aside className="chat-panel">
      <div className="chat-header">
        <span className="chat-title">AI Insights</span>
        <div className="chat-header-right">
          <span className="chat-badge">Backboard</span>
          <button className="chat-close-btn" onClick={onClose} title="Close chat">&#x2715;</button>
        </div>
      </div>

      <div className="chat-messages">
        {messages.length === 0 && !loading && (
          <div className="chat-welcome">
            <div className="chat-welcome-icon">&#x2728;</div>
            <p className="chat-welcome-title">Performance Analyst</p>
            <p className="chat-welcome-sub">Ask me anything about your donation bins</p>
            <div className="chat-starters">
              {STARTERS.map((q, i) => (
                <button key={i} className="chat-starter-btn" onClick={() => handleSend(q)} disabled={!ready}>
                  {q}
                </button>
              ))}
            </div>
          </div>
        )}

        {messages.map((msg, i) => (
          <div key={i} className={`chat-msg chat-msg-${msg.role}`}>
            <div className="chat-msg-bubble">{msg.content}</div>
          </div>
        ))}

        {loading && (
          <div className="chat-msg chat-msg-assistant">
            <div className="chat-msg-bubble chat-typing">
              <span className="typing-dot" /><span className="typing-dot" /><span className="typing-dot" />
            </div>
          </div>
        )}
        <div ref={bottomRef} />
      </div>

      <div className="chat-input-area">
        <input
          className="chat-input"
          type="text"
          placeholder={ready ? 'Ask about bin performance...' : 'Connecting...'}
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleSend(input)}
          disabled={!ready || loading}
        />
        <button
          className="chat-send-btn"
          onClick={() => handleSend(input)}
          disabled={!ready || loading || !input.trim()}
        >&#x27A4;</button>
      </div>
    </aside>
  );
}

// ─── App ─────────────────────────────────────────────────────────────────────

export default function App() {
  const data = useMemo(() => aggregate(RAW_DONATIONS, ACTIVE_CAUSE), []);
  const [chatOpen, setChatOpen] = useState(true);

  return (
    <div className="app">
      <Header />
      <div className="app-body">
        <div className="dashboard-content">
          <main className="main">
            <StatsRow stats={data.stats} />
            <div className="top-row">
              <GoalRing weeklyGoal={data.weeklyGoal} />
              <WeeklyTrendChart weeklyTrend={data.weeklyTrend} />
            </div>
            <div className="mid-row">
              <DonationFeed feed={data.feed} />
              <BinPerformance bins={data.bins} />
            </div>
          </main>
          <footer className="footer">
            <span className="footer-text">GiveClip Dashboard · Hamilton Food Share · {new Date().getFullYear()}</span>
          </footer>
        </div>
        {chatOpen && <ChatPanel data={data} onClose={() => setChatOpen(false)} />}
      </div>
      {!chatOpen && (
        <button className="chat-fab" onClick={() => setChatOpen(true)} title="Open AI Insights">
          &#x2728;
        </button>
      )}
    </div>
  );
}
