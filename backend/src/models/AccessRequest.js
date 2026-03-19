import mongoose from 'mongoose';

const accessRequestSchema = new mongoose.Schema({
  token: {
    type: String,
    required: true,
  },
  // The user who owns the shared folder/docs
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  // Identifier for what is being requested (folderId or docId)
  resourceId: {
    type: String,
    required: true,
  },
  resourceType: {
    type: String,
    enum: ['folder', 'document'],
    default: 'document',
  },
  // Verifier info (name/email from the request)
  verifierName: {
    type: String,
    default: 'Unknown Verifier',
  },
  verifierEmail: {
    type: String,
    default: '',
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'denied'],
    default: 'pending',
  },
  expiresAt: {
    type: Date,
    default: () => new Date(Date.now() + 24 * 60 * 60 * 1000), // 24h
  },
}, {
  timestamps: true,
});

const AccessRequest = mongoose.model('AccessRequest', accessRequestSchema);
export default AccessRequest;
