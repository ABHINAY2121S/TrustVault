import jwt from 'jsonwebtoken';
import Document from '../models/Document.js';
import VerificationLog from '../models/VerificationLog.js';
import { verifySignature } from '../utils/rsa.js';

// @desc    Verify a document via share link token
// @route   GET /api/verify/:token
// @access  Private (Verifier)
export const verifyDocumentLink = async (req, res) => {
  try {
    const { token } = req.params;

    // Decode expanding link
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    const document = await Document.findById(decoded.documentId).populate('issuerId', 'orgName publicKey');
    
    if (!document) {
      return res.status(404).json({ message: 'Document not found' });
    }

    let status = 'Success';
    let isTampered = false;

    // Verify cryptographic signature if issued by an issuer
    if (document.issuerId && document.signatureData && document.issuerId.publicKey) {
      const isValid = verifySignature(document.hash, document.signatureData, document.issuerId.publicKey);
      if (!isValid) {
        status = 'Tampered';
        isTampered = true;
      }
    }

    // Log the verification
    await VerificationLog.create({
      documentId: document._id,
      verifierId: req.user._id, // the verifier's id
      status,
      ipAddress: req.ip,
    });

    if (isTampered) {
      return res.status(400).json({ message: 'Document integrity compromised', document: null });
    }

    res.json({ document, verifiedAt: new Date() });
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
       return res.status(400).json({ message: 'Link has expired' });
    }
    console.error(error);
    res.status(500).json({ message: 'Verification failed' });
  }
};
