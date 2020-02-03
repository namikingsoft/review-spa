// Fernet-Like token
// https://github.com/fernet/spec/blob/0250c594a266036afb39aa574b88d9283810be47/Spec.md

const crypto = require('crypto');

const version = '1';
const separator = '-';
const cryptoAlgorism = 'aes-128-cbc';
const signerAlgorism = 'sha256';
const encodeTo = 'base64';
const decodeTo = 'utf-8';

const encrypt = (payload, key, iv) => {
  const cipher = crypto.createCipheriv(cryptoAlgorism, key, iv);
  return cipher.update(payload, decodeTo, encodeTo) + cipher.final(encodeTo);
};

const decrypt = (crypted, key, iv) => {
  const decipher = crypto.createDecipheriv(cryptoAlgorism, key, iv);
  return decipher.update(crypted, encodeTo, decodeTo) + decipher.final(decodeTo);
};

const createHmac = key => payload => crypto
  .createHmac(signerAlgorism, key)
  .update(payload)
  .digest(encodeTo)
  .toString();

const createFernetLike = ({
  signerKey,
  cryptoKey,
  randomBytes = () => crypto.randomBytes(16),
  getCurrentDate = () => new Date(),
}) => {
  const hmac = createHmac(signerKey);
  return {
    sign(payload, maxAgeSec) {
      const iv = randomBytes();
      const ivBase64 = iv.toString('base64');
      const crypted = encrypt(payload, cryptoKey, iv);
      const expired = String(Math.floor(getCurrentDate().getTime() / 1000) + maxAgeSec);
      const signature = hmac(version + expired + ivBase64 + crypted);
      return [version, expired, ivBase64, crypted, signature].join(separator);
    },
    verify(token) {
      const [header, expired, ivBase64, crypted, signature] = token.split(separator);
      if (Number(expired) * 1000 < getCurrentDate().getTime()) throw new Error('Expired token');
      if (signature === hmac(header + expired + ivBase64 + crypted)) {
        return decrypt(crypted, cryptoKey, Buffer.from(ivBase64, 'base64'));
      }
      throw new Error('Verification failure');
    },
  };
};

module.exports = createFernetLike;
