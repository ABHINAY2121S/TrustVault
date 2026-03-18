import Document from '../models/Document.js';
import User from '../models/User.js';
import { hashDocument } from '../utils/hash.js';
import { signDocument } from '../utils/rsa.js';

// @desc    Issuer uploads/issues a document and assigns to user
// @route   POST /api/issuer/issue
// @access  Private (Issuer)
export const issueDocument = async (req, res) => {
  try {
    const { title, category, fileUrl, userEmail, expiryDate, metadata } = req.body;

    const user = await User.findOne({ email: userEmail });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Hash the document
    const fakeBuffer = Buffer.from(fileUrl + title);
    const documentHash = hashDocument(fakeBuffer);

    // Sign the hash
    // In actual production, Issuer's private key should reside on their secure device/HSM
    // Here we use the db stored private key for simulation
    const signature = signDocument(documentHash, req.user.privateKey);

    const document = await Document.create({
      title,
      category,
      fileUrl,
      hash: documentHash,
      isVerified: true, // Issuer issued docs are pre-verified
      issuerId: req.user._id,
      userId: user._id,
      expiryDate,
      metadata,
      signatureData: signature,
    });

    res.status(201).json(document);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Get all issued documents by this issuer
// @route   GET /api/issuer/records
// @access  Private (Issuer)
export const getIssuedRecords = async (req, res) => {
  try {
    const documents = await Document.find({ issuerId: req.user._id }).populate('userId', 'name email');
    res.json(documents);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};
