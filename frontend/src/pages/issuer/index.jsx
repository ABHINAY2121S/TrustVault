import React, { useState, useEffect } from 'react';
import { Routes, Route, Link, useLocation } from 'react-router-dom';
import { FilePlus, Database } from 'lucide-react';
import IssueDoc from './IssueDoc';
import Records from './Records';
import api from '../../api';

const SidebarLink = ({ to, icon: Icon, label, active }) => (
  <Link
    to={to}
    className={`flex items-center space-x-3 px-4 py-3 rounded-xl transition-all ${
      active 
        ? 'bg-emerald-600/20 text-emerald-400 border border-emerald-500/30' 
        : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
    }`}
  >
    <Icon className="w-5 h-5" />
    <span className="font-medium">{label}</span>
  </Link>
);

const IssuerLayout = () => {
  const location = useLocation();
  const [records, setRecords] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchRecords = async () => {
    try {
      const { data } = await api.get('/issuer/records');
      setRecords(data);
    } catch (error) {
      console.error('Failed to fetch records:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRecords();
  }, []);

  return (
    <div className="flex bg-slate-950 min-h-[calc(100vh-65px)]">
      {/* Sidebar */}
      <div className="w-64 border-r border-slate-800 p-4 bg-slate-900/50 hidden md:block">
        <div className="space-y-2">
          <SidebarLink to="/issuer" icon={FilePlus} label="Issue Document" active={location.pathname === '/issuer'} />
          <SidebarLink to="/issuer/records" icon={Database} label="Issued Records" active={location.pathname === '/issuer/records'} />
        </div>
      </div>

      {/* Main Content Area */}
      <div className="flex-1 overflow-auto relative">
        <Routes>
          <Route path="/" element={<IssueDoc refreshRecords={fetchRecords} />} />
          <Route path="/records" element={<Records records={records} loading={loading} />} />
        </Routes>
      </div>
    </div>
  );
};

export default IssuerLayout;
