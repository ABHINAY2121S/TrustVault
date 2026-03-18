import crypto from 'crypto';

// Generate simulated RSA Key Pair
export const generateKeyPair = () => {
  const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
    modulusLength: 2048,
    publicKeyEncoding: {
      type: 'spki',
      format: 'pem',
    },
    privateKeyEncoding: {
      type: 'pkcs8',
      format: 'pem',
    },
  });
  return { publicKey, privateKey };
};

// Sign document hash with private key
export const signDocument = (documentHash, privateKey) => {
  const sign = crypto.createSign('SHA256');
  sign.update(documentHash);
  sign.end();
  const signature = sign.sign(privateKey, 'base64');
  return signature;
};

// Verify signature with public key
export const verifySignature = (documentHash, signature, publicKey) => {
  const verify = crypto.createVerify('SHA256');
  verify.update(documentHash);
  verify.end();
  return verify.verify(publicKey, signature, 'base64');
};
