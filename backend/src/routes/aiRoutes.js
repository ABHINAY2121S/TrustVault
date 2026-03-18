import express from 'express';
import { queryAI } from '../controllers/aiController.js';
import { protect } from '../middleware/auth.js';
import { roleGuard } from '../middleware/roleGuard.js';
import { roleGuard as enforceRole} from '../middleware/roleGuard.js';

const router = express.Router();

router.post('/query', protect, enforceRole('user'), queryAI);

export default router;
