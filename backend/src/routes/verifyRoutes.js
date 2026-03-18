import express from 'express';
import { verifyDocumentLink } from '../controllers/verifyController.js';
import { protect } from '../middleware/auth.js';
import { roleGuard } from '../middleware/roleGuard.js';
import { roleGuard as enforceRole} from '../middleware/roleGuard.js';

const router = express.Router();

// Verifier scans link/qr and hits this endpoint
router.get('/:token', protect, enforceRole('verifier'), verifyDocumentLink);

export default router;
