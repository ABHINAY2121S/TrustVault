import mongoose from 'mongoose';

const documentSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  category: {
    type: String,
    enum: ['Education', 'Medical', 'Government', 'Other'],
    default: 'Other',
  },
  fileUrl: {
    type: String, // URL to Firebase Storage
    required: true,
  },
  hash: {
    type: String, // SHA-256 hash of the file
    required: true,
  },
  isVerified: {
    type: Boolean,
    default: false,
  },
  issuerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Issuer',
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  expiryDate: {
    type: Date,
  },
  metadata: {
    type: Map,
    of: String, // Dynamic metadata like ID Number, Issue Date, etc.
  },
  signatureData: {
    type: String, // RSA signature from the issuer
  },
  bundleId: {
    type: String, // To group documents into bundles
  },
}, {
  timestamps: true,
});

const Document = mongoose.model('Document', documentSchema);

export default Document;
