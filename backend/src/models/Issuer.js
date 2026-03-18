import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const issuerSchema = new mongoose.Schema({
  orgName: {
    type: String,
    required: true,
  },
  orgType: {
    type: String,
    enum: ['College', 'Hospital', 'Government', 'Other'],
    required: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
  },
  password: {
    type: String,
    required: true,
  },
  publicKey: {
    type: String, // RSA Public Key for verification
  },
  privateKey: {
    type: String, // ONLY FOR SIMULATION - In real world, never store private key
  }
}, {
  timestamps: true,
});

issuerSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

issuerSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

const Issuer = mongoose.model('Issuer', issuerSchema);

export default Issuer;
