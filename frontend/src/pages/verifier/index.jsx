import React, { useState } from 'react';
import { Routes, Route, Link, useLocation } from 'react-router-dom';
import { ScanLine, CheckSquare } from 'lucide-react';
import Verify from './Verify';

const SidebarLink = ({ to, icon: Icon, label, active }) => (
  <Link
    to={to}
    className={`flex items-center space-x-3 px-4 py-3 rounded-xl transition-all ${
      active 
        ? 'bg-indigo-600/20 text-indigo-400 border border-indigo-500/30' 
        : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
    }`}
  >
    <Icon className="w-5 h-5" />
    <span className="font-medium">{label}</span>
  </Link>
);

const VerifierLayout = () => {
  const location = useLocation();

  return (
    <div className="flex bg-slate-950 min-h-[calc(100vh-65px)]">
      {/* Sidebar */}
      <div className="w-64 border-r border-slate-800 p-4 bg-slate-900/50 hidden md:block">
        <div className="space-y-2">
          <SidebarLink to="/verifier" icon={ScanLine} label="Verify Document" active={location.pathname === '/verifier'} />
        </div>
      </div>

      {/* Main Content Area */}
      <div className="flex-1 overflow-auto relative">
        <Routes>
          <Route path="/" element={<Verify />} />
        </Routes>
      </div>
    </div>
  );
};

export default VerifierLayout;
