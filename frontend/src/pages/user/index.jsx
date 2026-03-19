import React, { useState, useEffect } from 'react';
import { Routes, Route, Link, useLocation } from 'react-router-dom';
import { Wallet, Clock, Share2, FolderOpen, Bell } from 'lucide-react';
import WalletDashboard from './Wallet';
import Timeline from './Timeline';
import Share from './Share';
import Folders from './Folders';
import FloatingAI from './FloatingAI';
import api from '../../api';

const SidebarLink = ({ to, icon: Icon, label, active }) => (
  <Link
    to={to}
    className={`flex items-center space-x-3 px-4 py-3 rounded-xl transition-all ${
      active
        ? 'bg-purple-600/20 text-purple-400 border border-purple-500/30'
        : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
    }`}
  >
    <Icon className="w-5 h-5" />
    <span className="font-medium">{label}</span>
  </Link>
);

const ExpiryAlert = ({ docs }) => {
  if (!docs.length) return null;

  return (
    <div className="mx-4 mt-4 p-3 bg-amber-500/10 border border-amber-500/30 rounded-xl flex items-start gap-3">
      <Bell className="w-4 h-4 text-amber-400 mt-0.5 flex-shrink-0 animate-bounce" />
      <div className="min-w-0">
        <p className="text-amber-400 text-sm font-medium">
          {docs.length} document{docs.length > 1 ? 's' : ''} expiring soon
        </p>
        <p className="text-amber-400/70 text-xs mt-0.5 truncate">
          {docs.map(d => d.title).join(', ')}
        </p>
      </div>
    </div>
  );
};

const UserLayout = () => {
  const location = useLocation();
  const [documents, setDocuments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [expiringDocs, setExpiringDocs] = useState([]);

  const fetchDocuments = async () => {
    try {
      const { data } = await api.get('/documents');
      setDocuments(data);
    } catch (error) {
      console.error('Failed to fetch docs:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchExpiringDocs = async () => {
    try {
      const { data } = await api.get('/documents/expiring');
      setExpiringDocs(data);
    } catch (error) {
      // Non-critical, fail silently
      console.error('Failed to fetch expiring docs:', error);
    }
  };

  useEffect(() => {
    fetchDocuments();
    fetchExpiringDocs();
  }, []);

  const refreshDocs = () => {
    fetchDocuments();
    fetchExpiringDocs();
  };

  return (
    <div className="flex bg-slate-950 min-h-[calc(100vh-65px)]">
      {/* Sidebar */}
      <div className="w-64 border-r border-slate-800 flex flex-col bg-slate-900/50 hidden md:block">
        <div className="p-4 space-y-2 flex-1">
          <SidebarLink to="/user" icon={Wallet} label="My Wallet" active={location.pathname === '/user'} />
          <SidebarLink to="/user/timeline" icon={Clock} label="Timeline" active={location.pathname === '/user/timeline'} />
          <SidebarLink to="/user/folders" icon={FolderOpen} label="Folders" active={location.pathname === '/user/folders'} />
          <SidebarLink to="/user/share" icon={Share2} label="Share Bundles" active={location.pathname === '/user/share'} />
        </div>

        {/* Expiry Alert in Sidebar */}
        <ExpiryAlert docs={expiringDocs} />
        <div className="p-4" />
      </div>

      {/* Main Content Area */}
      <div className="flex-1 overflow-auto relative">
        {loading ? (
          <div className="flex items-center justify-center h-full text-slate-400">Loading your vault...</div>
        ) : (
          <Routes>
            <Route path="/" element={<WalletDashboard documents={documents} refreshDocs={refreshDocs} />} />
            <Route path="/timeline" element={<Timeline documents={documents} />} />
            <Route path="/folders" element={<Folders documents={documents} refreshDocs={refreshDocs} />} />
            <Route path="/share" element={<Share documents={documents} />} />
          </Routes>
        )}
      </div>

      {/* Floating AI Widget — globally available across all user pages */}
      <FloatingAI />
    </div>
  );
};

export default UserLayout;
