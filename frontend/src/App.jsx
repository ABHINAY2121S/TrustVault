import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './hooks/useAuth';

// Auth Pages
import Login from './pages/auth/Login';
import Register from './pages/auth/Register';

// Shared Components
import Navbar from './components/Navbar';

// Placeholder Pages (To be created)
const UserDashboard = () => <div className="p-8 text-center"><h1 className="text-2xl font-bold">User Dashboard Loading...</h1></div>;
const IssuerDashboard = () => <div className="p-8 text-center"><h1 className="text-2xl font-bold">Issuer Dashboard Loading...</h1></div>;
const VerifierDashboard = () => <div className="p-8 text-center"><h1 className="text-2xl font-bold">Verifier Dashboard Loading...</h1></div>;

const ProtectedRoute = ({ children, allowedRoles }) => {
  const { user, loading } = useAuth();
  
  if (loading) return <div>Loading...</div>;
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
              <UserDashboard />
            </ProtectedRoute>
          } />

          {/* Issuer Routes */}
          <Route path="/issuer/*" element={
            <ProtectedRoute allowedRoles={['issuer']}>
              <IssuerDashboard />
            </ProtectedRoute>
          } />

          {/* Verifier Routes */}
          <Route path="/verifier/*" element={
            <ProtectedRoute allowedRoles={['verifier']}>
              <VerifierDashboard />
            </ProtectedRoute>
          } />
          
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
    </div>
  );
}

export default App;
