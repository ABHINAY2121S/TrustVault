import React, { createContext, useState, useEffect } from 'react';
import api from '../api/index.js';

export const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const storedUser = localStorage.getItem('trustvault_user');
    if (storedUser) {
      try {
        setUser(JSON.parse(storedUser));
      } catch {
        localStorage.removeItem('trustvault_user');
      }
    }
    setLoading(false);
  }, []);

  // Login accepts { email, password, role }
  const login = async ({ email, password, role }) => {
    const { data } = await api.post('/auth/login', {
      email,
      password,
      loginAs: role,
    });
    setUser(data);
    localStorage.setItem('trustvault_user', JSON.stringify(data));
    return data;
  };

  // Register accepts { name, orgName, orgType, email, password, role }
  const register = async (userData) => {
    const { data } = await api.post('/auth/register', userData);
    setUser(data);
    localStorage.setItem('trustvault_user', JSON.stringify(data));
    return data;
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem('trustvault_user');
  };

  return (
    <AuthContext.Provider value={{ user, login, register, logout, loading }}>
      {!loading && children}
    </AuthContext.Provider>
  );
};
