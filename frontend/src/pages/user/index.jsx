import React, { useState, useEffect } from 'react';
import { Routes, Route, Link, useLocation } from 'react-router-dom';
import { Wallet, Clock, Share2, MessageSquareText } from 'lucide-react';
import WalletDashboard from './Wallet';
import Timeline from './Timeline';
import Share from './Share';
import AIChat from './AIChat';
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

const UserLayout = () => {
  const location = useLocation();
  const [documents, setDocuments] = useState([]);
  const [loading, setLoading] = useState(true);

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

  useEffect(() => {
    fetchDocuments();
  }, []);

  return (
    <div className="flex bg-slate-950 min-h-[calc(100vh-65px)]">
      {/* Sidebar */}
      <div className="w-64 border-r border-slate-800 p-4 bg-slate-900/50 hidden md:block">
        <div className="space-y-2">
          <SidebarLink to="/user" icon={Wallet} label="My Wallet" active={location.pathname === '/user'} />
          <SidebarLink to="/user/timeline" icon={Clock} label="Timeline" active={location.pathname === '/user/timeline'} />
          <SidebarLink to="/user/share" icon={Share2} label="Share Bundles" active={location.pathname === '/user/share'} />
          <SidebarLink to="/user/ai-chat" icon={MessageSquareText} label="AI Assistant" active={location.pathname === '/user/ai-chat'} />
        </div>
      </div>

      {/* Main Content Area */}
      <div className="flex-1 overflow-auto relative">
        {loading ? (
          <div className="flex items-center justify-center h-full text-slate-400">Loading your vault...</div>
        ) : (
          <Routes>
            <Route path="/" element={<WalletDashboard documents={documents} refreshDocs={fetchDocuments} />} />
            <Route path="/timeline" element={<Timeline documents={documents} />} />
            <Route path="/share" element={<Share documents={documents} />} />
            <Route path="/ai-chat" element={<AIChat documents={documents} />} />
          </Routes>
        )}
      </div>
    </div>
  );
};

export default UserLayout;
