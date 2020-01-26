const crypto = require('crypto');

const header = 'flv1';
const separator = '-';
const cryptAlgorism = 'AES-128-CBC';

const encrypt = (payload, key) => {
  const cipher = crypto.createCipher(cryptAlgorism, key);
  return cipher.update(payload, 'utf-8', 'base64') + cipher.final('base64');
};

const decrypt = (crypted, key) => {
  const decipher = crypto.createDecipher(cryptAlgorism, key);
  return decipher.update(crypted, 'base64', 'utf-8') + decipher.final('utf-8');
};

const createHKDF = (key, salt) => {
  const secureKey = crypto.createHmac('sha256', key)
    .update(salt)
    .digest('base64')
    .toString();
  return payload => crypto
    .createHmac('sha256', secureKey)
    .update(payload)
    .digest('base64')
    .toString();
}

const createFernetLike = ({ signerKey, cryptoKey, salt }) => {
  const hkdf = createHKDF(signerKey, salt);
  return {
    sign(payload, maxAgeSec) {
      const crypted = encrypt(payload, cryptoKey);
      const expired = String(Math.floor(new Date().getTime() / 1000) + maxAgeSec);
      const signature = hkdf(expired + crypted);
      return [header, expired, crypted, signature].join(separator);
    },
    verify(token) {
      if (!token.startsWith(header)) throw new Error('Token not found');
      const [, expired, crypted, signature] = token.split(separator);
      if (Number(expired) * 1000 < new Date().getTime()) throw new Error('Expired token');
      if (signature === hkdf(expired + crypted)) {
        return decrypt(crypted, cryptoKey);
      }
      throw new Error('Verification failure');
    },
  };
};

module.exports = createFernetLike;
