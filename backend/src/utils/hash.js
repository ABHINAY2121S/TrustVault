import crypto from 'crypto';

// Hash a file buffer using SHA-256
export const hashDocument = (buffer) => {
  const hashSum = crypto.createHash('sha256');
  hashSum.update(buffer);
  return hashSum.digest('hex');
};
