import QRCode from 'qrcode';
import jwt from 'jsonwebtoken';

// Generate QR Code as Data URI (Base64 Image)
export const generateQRCode = async (data) => {
  try {
    const qrUri = await QRCode.toDataURL(data);
    return qrUri;
  } catch (err) {
    console.error(err);
    throw new Error('Failed to generate QR code');
  }
};

// Generate an expiring share link token (e.g., 24 hours)
export const generateShareToken = (documentId, bundleId = null) => {
  return jwt.sign({ documentId, bundleId }, process.env.JWT_SECRET, {
    expiresIn: '24h',
  });
};
