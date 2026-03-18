import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import Issuer from '../models/Issuer.js';

// Generate JWT
const generateToken = (id, role) => {
  return jwt.sign({ id, role }, process.env.JWT_SECRET, {
    expiresIn: '30d',
  });
};

// @desc    Register a new user, issuer, or verifier
// @route   POST /api/auth/register
// @access  Public
export const register = async (req, res) => {
  try {
    const { name, email, password, role, orgName, orgType } = req.body;

    if (!email || !password || !role) {
      return res.status(400).json({ message: 'Please add all required fields' });
    }

    // Check if user/issuer already exists
    let exists;
    if (role === 'issuer') {
      exists = await Issuer.findOne({ email });
    } else {
      exists = await User.findOne({ email });
    }

    if (exists) {
      return res.status(400).json({ message: 'Email already exists' });
    }

    // Create record
    if (role === 'issuer') {
      const issuer = await Issuer.create({
        orgName,
        orgType,
        email,
        password,
      });

      if (issuer) {
        res.status(201).json({
          _id: issuer.id,
          orgName: issuer.orgName,
          email: issuer.email,
          role: 'issuer',
          token: generateToken(issuer._id, 'issuer'),
        });
      }
    } else {
      // User or Verifier
      const user = await User.create({
        name,
        email,
        password,
        role,
      });

      if (user) {
        res.status(201).json({
          _id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          token: generateToken(user._id, user.role),
        });
      }
    }
  } catch (error) {
    console.error('Register error:', error.message);
    res.status(500).json({ message: 'Server error', detail: error.message });
  }
};

// @desc    Authenticate a user/issuer
// @route   POST /api/auth/login
// @access  Public
export const login = async (req, res) => {
  try {
    const { email, password, loginAs } = req.body;

    if (!email || !password || !loginAs) {
      return res.status(400).json({ message: 'Please add all fields including loginAs (user/issuer/verifier)' });
    }

    if (loginAs === 'issuer') {
      const issuer = await Issuer.findOne({ email });
      if (issuer && (await issuer.matchPassword(password))) {
        res.json({
          _id: issuer.id,
          orgName: issuer.orgName,
          email: issuer.email,
          role: 'issuer',
          token: generateToken(issuer._id, 'issuer'),
        });
      } else {
        res.status(401).json({ message: 'Invalid credentials' });
      }
    } else {
      const user = await User.findOne({ email });
      // ensure role matches login type
      if (user && user.role === loginAs && (await user.matchPassword(password))) {
        res.json({
          _id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          token: generateToken(user._id, user.role),
        });
      } else {
        res.status(401).json({ message: 'Invalid credentials or wrong role selected' });
      }
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};
