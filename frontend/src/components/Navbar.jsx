import React from 'react';
import { useAuth } from '../hooks/useAuth';
import { useNavigate, Link } from 'react-router-dom';
import { ShieldCheck, LogOut, User, Building, UserCheck } from 'lucide-react';

const Navbar = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  if (!user) return null;

  return (
    <nav className="bg-slate-900 border-b border-slate-800 px-6 py-3">
      <div className="max-w-7xl mx-auto flex items-center justify-between">
        <Link to={`/${user.role}`} className="flex items-center space-x-2">
          <ShieldCheck className="w-8 h-8 text-purple-500" />
          <span className="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-purple-400 to-indigo-500">
            TrustVault
          </span>
        </Link>
        
        <div className="flex items-center space-x-6">
          <div className="flex items-center space-x-2 text-slate-300">
            {user.role === 'user' && <User className="w-4 h-4 text-purple-400" />}
            {user.role === 'issuer' && <Building className="w-4 h-4 text-emerald-400" />}
            {user.role === 'verifier' && <UserCheck className="w-4 h-4 text-indigo-400" />}
            
            <span className="font-medium text-sm">
              {user.name || user.orgName}
              <span className="ml-2 px-2 py-0.5 rounded-full bg-slate-800 text-xs text-slate-400 uppercase tracking-wider">
                {user.role}
              </span>
            </span>
          </div>
          
          <button 
            onClick={handleLogout}
            className="flex items-center space-x-2 text-slate-400 hover:text-red-400 transition-colors text-sm font-medium"
          >
            <LogOut className="w-4 h-4" />
            <span>Sign Out</span>
          </button>
        </div>
      </div>
    </nav>
  );
};

export default Navbar;
