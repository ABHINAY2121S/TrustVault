import Document from '../models/Document.js';
import { hashDocument } from '../utils/hash.js';

// @desc    Upload User Document (Mocked for now, just saves metadata)
// @route   POST /api/documents
// @access  Private (User)
export const uploadDocument = async (req, res) => {
  try {
    const { title, category, fileUrl, expiryDate, metadata } = req.body;
    
    // In a real scenario, req.file buffer is hashed
    // For MVP with JSON body, we mock the hash
    const fakeBuffer = Buffer.from(fileUrl + title);
    const hash = hashDocument(fakeBuffer);

    const document = await Document.create({
      title,
      category,
      fileUrl,
      hash,
      userId: req.user._id,
      expiryDate,
      metadata,
    });

    res.status(201).json(document);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Get user documents
// @route   GET /api/documents
// @access  Private (User)
export const getUserDocuments = async (req, res) => {
  try {
    const documents = await Document.find({ userId: req.user._id }).populate('issuerId', 'orgName');
    res.json(documents);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};
