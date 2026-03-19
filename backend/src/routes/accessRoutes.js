import express from 'express';
import {
  requestAccess,
  getPendingRequests,
  respondToRequest,
  checkAccessStatus,
} from '../controllers/accessController.js';
import { protect } from '../middleware/auth.js';
import { roleGuard } from '../middleware/roleGuard.js';

const router = express.Router();

// Public endpoints (verifier web calls these)
router.post('/request', requestAccess);
router.get('/check/:requestId', checkAccessStatus);

// User-only endpoints
router.get('/pending', protect, roleGuard('user'), getPendingRequests);
router.put('/:id/respond', protect, roleGuard('user'), respondToRequest);

export default router;
