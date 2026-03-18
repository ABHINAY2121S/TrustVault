import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import Issuer from '../models/Issuer.js';

export const protect = async (req, res, next) => {
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    try {
      // Get token from header
      token = req.headers.authorization.split(' ')[1];

      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // We might have an Issuer or a User logging in
      // Let's assume the payload has { id, role }
      if (decoded.role === 'issuer') {
        req.user = await Issuer.findById(decoded.id).select('-password');
        req.user.role = 'issuer'; // explicitly set since schema might not have it default for issuer in same way as user
      } else {
        req.user = await User.findById(decoded.id).select('-password');
      }

      if (!req.user) {
        return res.status(401).json({ message: 'Not authorized, user not found' });
      }

      next();
    } catch (error) {
      console.error(error);
      res.status(401).json({ message: 'Not authorized, token failed' });
    }
  }

  if (!token) {
    res.status(401).json({ message: 'Not authorized, no token' });
  }
};
