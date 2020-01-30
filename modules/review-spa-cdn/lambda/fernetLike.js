const crypto = require('crypto');

const version = 'flv1';
const separator = '-';
const cryptoAlgorism = 'aes-128-cbc';
const signerAlgorism = 'sha256';
const encodeTo = 'base64';
const decodeTo = 'utf-8';

const encrypt = (payload, key) => {
  const cipher = crypto.createCipher(cryptoAlgorism, key);
  return cipher.update(payload, decodeTo, encodeTo) + cipher.final(encodeTo);
};

const decrypt = (crypted, key) => {
  const decipher = crypto.createDecipher(cryptoAlgorism, key);
  return decipher.update(crypted, encodeTo, decodeTo) + decipher.final(decodeTo);
};

const createHKDF = (key, salt) => {
  const secureKey = crypto.createHmac(signerAlgorism, key)
    .update(salt)
    .digest(encodeTo)
    .toString();
  return payload => crypto
    .createHmac(signerAlgorism, secureKey)
    .update(payload)
    .digest(encodeTo)
    .toString();
}

const createFernetLike = ({ signerKey, cryptoKey, salt, getCurrentDate = () => new Date() }) => {
  const hkdf = createHKDF(signerKey, salt);
  return {
    sign(payload, maxAgeSec) {
      const crypted = encrypt(payload, cryptoKey);
      const expired = String(Math.floor(getCurrentDate().getTime() / 1000) + maxAgeSec);
      const signature = hkdf(version + expired + crypted);
      return [version, expired, crypted, signature].join(separator);
    },
    verify(token) {
      const [header, expired, crypted, signature] = token.split(separator);
      if (Number(expired) * 1000 < getCurrentDate().getTime()) throw new Error('Expired token');
      if (signature === hkdf(header + expired + crypted)) {
        return decrypt(crypted, cryptoKey);
      }
      throw new Error('Verification failure');
    },
  };
};

module.exports = createFernetLike;
