import Document from '../models/Document.js';
import { hashDocument } from '../utils/hash.js';
import OpenAI from 'openai';
import multer from 'multer';

// --- Multer setup (memory storage – no disk writes needed) ---
export const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB max
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
    if (allowed.includes(file.mimetype)) cb(null, true);
    else cb(new Error('Only JPEG, PNG, WebP images and PDFs are allowed'));
  },
});

// --- AI Client for OCR ---
const aiClient = new OpenAI({
  baseURL: process.env.AI_BASE_URL || 'https://models.github.ai/inference',
  apiKey: process.env.GITHUB_TOKEN || 'dummy_key',
});

// --- OCR helper: extract text from uploaded image using AI Vision ---
async function extractTextFromImage(fileBuffer, mimeType, userName) {
  try {
    // Only vision works on images; for PDFs we skip OCR and mark partial
    if (mimeType === 'application/pdf') {
      return { ocrText: '[PDF - OCR not supported]', matchedUser: false };
    }

    const base64Image = fileBuffer.toString('base64');
    const dataUrl = `data:${mimeType};base64,${base64Image}`;

    const response = await aiClient.chat.completions.create({
      model: process.env.AI_MODEL || 'openai/gpt-4o-mini',
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: `You are a document OCR assistant. Extract ALL visible text from this document image. Return ONLY the raw extracted text, nothing else. No formatting, no explanations.`,
            },
            {
              type: 'image_url',
              image_url: { url: dataUrl },
            },
          ],
        },
      ],
      max_tokens: 1000,
    });

    const ocrText = response.choices[0].message.content || '';

    // Check if user's name appears in the document text (basic authenticity check)
    const nameParts = userName.toLowerCase().split(' ').filter(p => p.length > 2);
    const textLower = ocrText.toLowerCase();
    const matchedUser = nameParts.some(part => textLower.includes(part));

    return { ocrText, matchedUser };
  } catch (err) {
    console.error('OCR error:', err.message);
    return { ocrText: '', matchedUser: false };
  }
}

// @desc    Upload local document with OCR scan
// @route   POST /api/documents/upload
// @access  Private (User)
export const uploadDocument = async (req, res) => {
  try {
    const { title, category, expiryDate, metadata } = req.body;

    let fileUrl = req.body.fileUrl || '';
    let ocrText = '';
    let verificationStatus = 'unverified';

    if (req.file) {
      // Build a mock storage URL (in production, upload to Firebase/S3 here)
      fileUrl = `local://uploads/${Date.now()}_${req.file.originalname}`;

      // Run OCR scan
      const userName = req.user.name || '';
      const scanResult = await extractTextFromImage(req.file.buffer, req.file.mimetype, userName);
      ocrText = scanResult.ocrText;

      // Set verification status based on OCR match
      if (scanResult.matchedUser) {
        verificationStatus = 'partially_verified';
      } else {
        verificationStatus = 'unverified';
      }
    }

    const fakeBuffer = Buffer.from(fileUrl + title);
    const hash = hashDocument(fakeBuffer);

    let parsedMetadata = {};
    if (metadata) {
      try {
        parsedMetadata = typeof metadata === 'string' ? JSON.parse(metadata) : metadata;
      } catch (_) {}
    }

    const document = await Document.create({
      title,
      category: category || 'Other',
      fileUrl,
      hash,
      userId: req.user._id,
      expiryDate: expiryDate || null,
      metadata: parsedMetadata,
      verificationStatus,
      ocrText,
    });

    res.status(201).json(document);
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ message: 'Server Error', details: error.message });
  }
};

// @desc    Get user documents (optionally filter by year)
// @route   GET /api/documents
// @access  Private (User)
export const getUserDocuments = async (req, res) => {
  try {
    const documents = await Document.find({ userId: req.user._id })
      .populate('issuerId', 'orgName')
      .sort({ createdAt: -1 });
    res.json(documents);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Delete a user-uploaded document (only unverified/partially_verified)
// @route   DELETE /api/documents/:id
// @access  Private (User)
export const deleteDocument = async (req, res) => {
  try {
    const doc = await Document.findOne({ _id: req.params.id, userId: req.user._id });
    if (!doc) return res.status(404).json({ message: 'Document not found' });

    if (doc.verificationStatus === 'verified') {
      return res.status(403).json({ message: 'Cannot delete an issuer-verified document' });
    }

    await doc.deleteOne();
    res.json({ message: 'Document deleted successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Get documents expiring within 30 days
// @route   GET /api/documents/expiring
// @access  Private (User)
export const getExpiringDocuments = async (req, res) => {
  try {
    const now = new Date();
    const in30Days = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    const expiring = await Document.find({
      userId: req.user._id,
      expiryDate: { $gte: now, $lte: in30Days },
    }).populate('issuerId', 'orgName');

    res.json(expiring);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server Error' });
  }
};
