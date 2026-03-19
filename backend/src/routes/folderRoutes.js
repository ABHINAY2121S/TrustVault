import express from 'express';
import {
  createFolder,
  getFolders,
  getFolderDocuments,
  addDocToFolder,
  removeDocFromFolder,
  deleteFolder,
} from '../controllers/folderController.js';
import { shareFolder } from '../controllers/verifyController.js';
import { protect } from '../middleware/auth.js';
import { roleGuard } from '../middleware/roleGuard.js';

const router = express.Router();

const userOnly = [protect, roleGuard('user')];

router.route('/')
  .get(...userOnly, getFolders)
  .post(...userOnly, createFolder);

router.get('/:id/documents', ...userOnly, getFolderDocuments);
router.post('/:id/share', ...userOnly, shareFolder);
router.put('/:folderId/add/:docId', ...userOnly, addDocToFolder);
router.put('/remove/:docId', ...userOnly, removeDocFromFolder);
router.delete('/:id', ...userOnly, deleteFolder);

export default router;
