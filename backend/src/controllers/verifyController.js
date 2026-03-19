import jwt from 'jsonwebtoken';
import Document from '../models/Document.js';
import Folder from '../models/Folder.js';
import VerificationLog from '../models/VerificationLog.js';
import { verifySignature } from '../utils/rsa.js';
import { generateQRCode } from '../utils/qr.js';

// @desc    Generate a secure share link + QR code for a document
// @route   POST /api/documents/share/:id
// @access  Private (User)
export const shareDocument = async (req, res) => {
  try {
    const doc = await Document.findOne({ _id: req.params.id, userId: req.user._id });
    if (!doc) return res.status(404).json({ message: 'Document not found' });

    const token = jwt.sign({ documentId: doc._id }, process.env.JWT_SECRET, { expiresIn: '24h' });
    const frontendUrl = process.env.FRONTEND_URL || 'http://192.168.1.4:5173';
    const verifyUrl = `${frontendUrl}/verifier?token=${token}`;
    const qrUri = await generateQRCode(verifyUrl);

    res.json({ token, qrUri, verifyUrl });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Failed to generate share link' });
  }
};

// @desc    Generate a secure share link + QR code for a FOLDER
// @route   POST /api/folders/share/:id
// @access  Private (User)
export const shareFolder = async (req, res) => {
  try {
    const folder = await Folder.findOne({ _id: req.params.id, userId: req.user._id });
    if (!folder) return res.status(404).json({ message: 'Folder not found' });

    // Sign with folderId so accessController can distinguish folder vs document
    const token = jwt.sign({ folderId: folder._id }, process.env.JWT_SECRET, { expiresIn: '24h' });
    const frontendUrl = process.env.FRONTEND_URL || 'http://192.168.1.4:5173';
    const verifyUrl = `${frontendUrl}/verifier?token=${token}`;
    const qrUri = await generateQRCode(verifyUrl);

    res.json({ token, qrUri, verifyUrl });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Failed to generate folder share link' });
  }
};

// @desc    Verify a document or folder via share link token
// @route   GET /api/verify/:token
// @access  Private (Verifier)
export const verifyDocumentLink = async (req, res) => {
  try {
    const { token } = req.params;
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // ── FOLDER TOKEN ──────────────────────────────────────────────────────
    if (decoded.folderId) {
      const folder = await Folder.findById(decoded.folderId);
      if (!folder) return res.status(404).json({ message: 'Folder not found' });

      const documents = await Document.find({ folderId: decoded.folderId })
        .populate('issuerId', 'orgName publicKey');

      return res.json({
        type: 'folder',
        folder: { _id: folder._id, name: folder.name },
        documents,
        verifiedAt: new Date(),
      });
    }

    // ── DOCUMENT TOKEN ────────────────────────────────────────────────────
    const document = await Document.findById(decoded.documentId)
      .populate('issuerId', 'orgName publicKey');

    if (!document) return res.status(404).json({ message: 'Document not found' });

    let status = 'Success';
    let isTampered = false;

    if (document.issuerId && document.signatureData && document.issuerId.publicKey) {
      const isValid = verifySignature(document.hash, document.signatureData, document.issuerId.publicKey);
      if (!isValid) { status = 'Tampered'; isTampered = true; }
    }

    await VerificationLog.create({
      documentId: document._id,
      verifierId: req.user._id,
      status,
      ipAddress: req.ip,
    });

    if (isTampered) {
      return res.status(400).json({ message: 'Document integrity compromised', document: null });
    }

    res.json({ type: 'document', document, verifiedAt: new Date() });
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(400).json({ message: 'Link has expired' });
    }
    console.error(error);
    res.status(500).json({ message: 'Verification failed' });
  }
};

