import mongoose from 'mongoose';

const verificationLogSchema = new mongoose.Schema({
  documentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Document',
    required: true,
  },
  verifierId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User', // The user who verified it
    required: true,
  },
  status: {
    type: String,
    enum: ['Success', 'Failed', 'Tampered'],
    required: true,
  },
  ipAddress: {
    type: String,
  },
}, {
  timestamps: true,
});

const VerificationLog = mongoose.model('VerificationLog', verificationLogSchema);

export default VerificationLog;
