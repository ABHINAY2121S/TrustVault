import Document from '../models/Document.js';
import User from '../models/User.js';
import Issuer from '../models/Issuer.js';
import Folder from '../models/Folder.js';
import { hashDocument } from '../utils/hash.js';
import { generateKeyPair, signDocument } from '../utils/rsa.js';
import fs from 'fs';

// @desc    Issuer uploads/issues a document and assigns to user
// @route   POST /api/issuer/issue
// @access  Private (Issuer)
export const issueDocument = async (req, res) => {
  try {
    const { title, category, userEmail, expiryDate, idNumber } = req.body;

    if (!title || !userEmail) {
      return res.status(400).json({ message: 'Title and user email are required' });
    }
    if (!req.file) {
      return res.status(400).json({ message: 'Please attach a document file (PDF/image)' });
    }

    const user = await User.findOne({ email: userEmail, role: 'user' });
    if (!user) {
      return res.status(404).json({ message: `No registered user found with email: ${userEmail}` });
    }

    // Auto-generate RSA key pair for issuer if they don't have one yet
    let issuerRecord = await Issuer.findById(req.user._id);
    if (!issuerRecord.privateKey || !issuerRecord.publicKey) {
      const { publicKey, privateKey } = generateKeyPair();
      issuerRecord.publicKey = publicKey;
      issuerRecord.privateKey = privateKey;
      await issuerRecord.save();
    }

    // Hash the actual file from disk
    const fileBuffer = fs.readFileSync(req.file.path);
    const documentHash = hashDocument(fileBuffer);

    // Sign the hash
    const signature = signDocument(documentHash, issuerRecord.privateKey);

    // Build a publicly accessible URL for the file
    const fileUrl = `/uploads/${req.file.filename}`;

    const document = await Document.create({
      title,
      category: category || 'Other',
      fileUrl,
      hash: documentHash,
      verificationStatus: 'verified',
      issuerId: issuerRecord._id,
      userId: user._id,
      expiryDate: expiryDate || null,
      metadata: {
        'ID Number': idNumber || '',
        'Issued On': new Date().toISOString(),
        'File Name': req.file.originalname,
        'File Size': `${(req.file.size / 1024).toFixed(1)} KB`,
        'File Type': req.file.mimetype,
      },
      signatureData: signature,
    });

    // ── Auto-assign to category folder (create if not exists) ──────────────
    const folderName = category || 'Other';
    const folderColors = {
      Education: '#3b82f6',
      Medical: '#10b981',
      Government: '#f59e0b',
      Other: '#7c3aed',
    };
    const folderIcons = {
      Education: 'school',
      Medical: 'local_hospital',
      Government: 'account_balance',
      Other: 'folder',
    };

    let folder = await Folder.findOne({ userId: user._id, name: folderName });
    if (!folder) {
      folder = await Folder.create({
        name: folderName,
        userId: user._id,
        color: folderColors[folderName] || '#7c3aed',
        icon: folderIcons[folderName] || 'folder',
      });
    }

    // Add the document to the folder
    await Document.findByIdAndUpdate(document._id, { folderId: folder._id });

    res.status(201).json({ ...document.toObject(), folderId: folder._id });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error', detail: error.message });
  }
};

// @desc    Get all issued documents by this issuer
// @route   GET /api/issuer/records
// @access  Private (Issuer)
export const getIssuedRecords = async (req, res) => {
  try {
    const documents = await Document.find({ issuerId: req.user._id })
      .populate('userId', 'name email');
    res.json(documents);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};
