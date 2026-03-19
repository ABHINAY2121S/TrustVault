import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './hooks/useAuth';

// Auth Pages
import Login from './pages/auth/Login';
import Register from './pages/auth/Register';

// Shared Components
import Navbar from './components/Navbar';

// Real Dashboard Layouts
import UserLayout from './pages/user/index';
import IssuerLayout from './pages/issuer/index';
import VerifierLayout from './pages/verifier/index';

const ProtectedRoute = ({ children, allowedRoles }) => {
  const { user, loading } = useAuth();
  
  if (loading) return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="text-slate-400 text-sm animate-pulse">Loading TrustVault...</div>
    </div>
  );
  if (!user) return <Navigate to="/login" replace />;
  if (allowedRoles && !allowedRoles.includes(user.role)) {
    return <Navigate to={`/${user.role}`} replace />;
  }
  return children;
};

function App() {
  const { user } = useAuth();

  return (
    <div className="min-h-screen bg-slate-950 flex flex-col">
      {user && <Navbar />}
      
      <main className="flex-1">
        <Routes>
          {/* Public Routes */}
          <Route path="/" element={<Navigate to={user ? `/${user.role}` : "/login"} replace />} />
          <Route path="/login" element={user ? <Navigate to={`/${user.role}`} replace /> : <Login />} />
          <Route path="/register" element={user ? <Navigate to={`/${user.role}`} replace /> : <Register />} />

          {/* User Routes */}
          <Route path="/user/*" element={
            <ProtectedRoute allowedRoles={['user']}>
              <UserLayout />
            </ProtectedRoute>
          } />

          {/* Issuer Routes */}
          <Route path="/issuer/*" element={
            <ProtectedRoute allowedRoles={['issuer']}>
              <IssuerLayout />
            </ProtectedRoute>
          } />

          {/* Verifier Routes */}
          <Route path="/verifier/*" element={
            <ProtectedRoute allowedRoles={['verifier']}>
              <VerifierLayout />
            </ProtectedRoute>
          } />
          
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
    </div>
  );
}

export default App;
