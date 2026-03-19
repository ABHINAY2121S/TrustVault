import express from 'express';
import {
  uploadDocument,
  getUserDocuments,
  deleteDocument,
  getExpiringDocuments,
  upload,
} from '../controllers/documentController.js';
import { protect } from '../middleware/auth.js';
import { roleGuard } from '../middleware/roleGuard.js';
import { shareDocument } from '../controllers/verifyController.js';

const router = express.Router();
const userOnly = [protect, roleGuard('user')];

// Standard document endpoints
router.route('/')
  .post(...userOnly, upload.single('file'), uploadDocument)
  .get(...userOnly, getUserDocuments);

router.get('/expiring', ...userOnly, getExpiringDocuments);
router.delete('/:id', ...userOnly, deleteDocument);

// Share / QR
router.post('/share/:id', ...userOnly, shareDocument);

export default router;
