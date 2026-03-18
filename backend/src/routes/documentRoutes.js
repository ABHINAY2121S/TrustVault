import express from 'express';
import { uploadDocument, getUserDocuments } from '../controllers/documentController.js';
import { protect } from '../middleware/auth.js';
import { roleGuard } from '../middleware/roleGuard.js';
import { roleGuard as enforceRole} from '../middleware/roleGuard.js';

const router = express.Router();

router.route('/')
  .post(protect, enforceRole('user'), uploadDocument)
  .get(protect, enforceRole('user'), getUserDocuments);

export default router;
