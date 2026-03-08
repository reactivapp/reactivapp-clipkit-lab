import React, { useState, useEffect, useRef } from 'react';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell,
  PieChart, Pie
} from 'recharts';

// ─── Mock Data ───────────────────────────────────────────────────────────────

const CHARITY = {
  name: 'Hamilton Food Share',
  city: 'Hamilton, ON',
  costPerMeal: 4.0,
};

const STATS = {
  mealsToday: 312,
  dollarsToday: 1248,
  donationsToday: 47,
  avgDonation: 26.55,
};

const WEEKLY_GOAL = { current: 848, target: 1000 };

const DONATIONS = [
  { id: 1, timeAgo: '2 min ago',  amount: 20,  meals: 5,  bin: 'Fortinos — Main St' },
  { id: 2, timeAgo: '5 min ago',  amount: 10,  meals: 2,  bin: 'Walmart — Rymal Rd' },
  { id: 3, timeAgo: '8 min ago',  amount: 50,  meals: 12, bin: 'Loblaws — King St' },
  { id: 4, timeAgo: '12 min ago', amount: 15,  meals: 3,  bin: 'Fortinos — Main St' },
  { id: 5, timeAgo: '18 min ago', amount: 25,  meals: 6,  bin: 'Walmart — Rymal Rd' },
  { id: 6, timeAgo: '24 min ago', amount: 10,  meals: 2,  bin: 'Loblaws — King St' },
  { id: 7, timeAgo: '31 min ago', amount: 100, meals: 25, bin: 'Fortinos — Main St' },
  { id: 8, timeAgo: '45 min ago', amount: 20,  meals: 5,  bin: 'Walmart — Rymal Rd' },
  { id: 9, timeAgo: '1 hr ago',   amount: 30,  meals: 7,  bin: 'Loblaws — King St' },
  { id: 10, timeAgo: '1 hr ago',  amount: 15,  meals: 3,  bin: 'Fortinos — Main St' },
];

const BINS = [
  { name: 'Fortinos — Main St',   donations: 18, dollars: 540, change: +12.3 },
  { name: 'Walmart — Rymal Rd',   donations: 16, dollars: 480, change: +8.7 },
  { name: 'Loblaws — King St',    donations: 13, dollars: 228, change: -2.1 },
];

const WEEKLY_TREND = [
  { day: 'Mon', meals: 95 },
  { day: 'Tue', meals: 110 },
  { day: 'Wed', meals: 130 },
  { day: 'Thu', meals: 145 },
  { day: 'Fri', meals: 168 },
  { day: 'Sat', meals: 120 },
  { day: 'Sun', meals: 80 },
];

// ─── Circular Progress Ring ──────────────────────────────────────────────────

function GoalRing() {
  const pct = (WEEKLY_GOAL.current / WEEKLY_GOAL.target) * 100;
  const ringData = [
    { name: 'done', value: pct },
    { name: 'left', value: 100 - pct },
  ];

  return (
    <div className="card goal-ring-card">
      <div className="goal-ring-header">
        <span className="section-label">Weekly Goal</span>
        <span className="goal-pill">{WEEKLY_GOAL.current.toLocaleString()} / {WEEKLY_GOAL.target.toLocaleString()}</span>
      </div>
      <div className="goal-ring-body">
        <div className="ring-wrapper">
          <PieChart width={160} height={160}>
            <Pie
              data={ringData}
              cx={75}
              cy={75}
              innerRadius={52}
              outerRadius={68}
              startAngle={90}
              endAngle={-270}
              dataKey="value"
              stroke="none"
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
            <span className="ring-stat-val">{(WEEKLY_GOAL.target - WEEKLY_GOAL.current).toLocaleString()}</span>
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
          <span className="logo-icon">🍃</span>
          <span className="logo-text">GiveClip</span>
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

function StatsRow() {
  return (
    <div className="stats-row">
      <StatCard label="Meals Funded Today" value={STATS.mealsToday.toLocaleString()} sub="12% vs yesterday" accent="#2E7D32" />
      <StatCard label="Dollars Raised Today" value={`$${STATS.dollarsToday.toLocaleString()}`} sub="8% vs yesterday" accent="#4CAF50" />
      <StatCard label="Donations Today" value={STATS.donationsToday} sub="5 more than avg" accent="#66BB6A" />
      <StatCard label="Avg. Donation" value={`$${STATS.avgDonation}`} accent="#81C784" />
    </div>
  );
}

// ─── Live Donation Feed ──────────────────────────────────────────────────────

function DonationFeed() {
  return (
    <div className="card feed-card">
      <div className="card-header-row">
        <h2 className="section-label">
          <span className="pulse-dot" />
          Live Donations
        </h2>
        <span className="card-header-sub">{DONATIONS.length} recent</span>
      </div>
      <div className="feed-list">
        {DONATIONS.map((d) => (
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

function BinPerformance() {
  const maxDollars = Math.max(...BINS.map((b) => b.dollars));

  return (
    <div className="card">
      <div className="card-header-row">
        <h2 className="section-label">Bin Performance</h2>
        <span className="card-header-sub">3 locations</span>
      </div>
      <div className="bin-list">
        {BINS.map((bin) => (
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

function WeeklyTrendChart() {
  const totalMeals = WEEKLY_TREND.reduce((sum, d) => sum + d.meals, 0);

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
          <BarChart data={WEEKLY_TREND} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#2a2a2a" vertical={false} />
            <XAxis dataKey="day" stroke="#666" tick={{ fontSize: 12, fill: '#888' }} axisLine={false} tickLine={false} />
            <YAxis stroke="#666" tick={{ fontSize: 12, fill: '#888' }} axisLine={false} tickLine={false} />
            <Tooltip content={<CustomTooltip />} cursor={{ fill: 'rgba(46,125,50,0.08)' }} />
            <Bar dataKey="meals" radius={[8, 8, 0, 0]} barSize={36}>
              {WEEKLY_TREND.map((entry, index) => (
                <Cell key={index} fill={index === 4 ? '#4CAF50' : '#2E7D32'} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}

// ─── App ─────────────────────────────────────────────────────────────────────

export default function App() {
  return (
    <div className="app">
      <Header />
      <main className="main">
        <StatsRow />
        <div className="top-row">
          <GoalRing />
          <WeeklyTrendChart />
        </div>
        <div className="mid-row">
          <DonationFeed />
          <BinPerformance />
        </div>
      </main>
      <footer className="footer">
        <span className="footer-text">GiveClip Dashboard · Hamilton Food Share · {new Date().getFullYear()}</span>
      </footer>
    </div>
  );
}
