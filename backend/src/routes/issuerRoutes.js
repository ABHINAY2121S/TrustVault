import express from 'express';
import { issueDocument, getIssuedRecords } from '../controllers/issuerController.js';
import { protect } from '../middleware/auth.js';
import { roleGuard } from '../middleware/roleGuard.js';

const router = express.Router();

router.route('/issue').post(protect, roleGuard('issuer'), issueDocument);
router.route('/records').get(protect, roleGuard('issuer'), getIssuedRecords);

export default router;
