const createFernetLike = require('./fernetLike');

const signerKey = '16bytesaaaaaaaaa';
const cryptoKey = '16bytesbbbbbbbbb';
const iv = Buffer.from('16bytesccccccccc');

test('sign', () => {
  const { sign } = createFernetLike({ signerKey, cryptoKey, randomBytes: () => iv, getCurrentDate: () => new Date(1000) });
  const token = sign('I want to encrypt this string.', 60);

  expect(token).toBe('1-61-MTZieXRlc2NjY2NjY2NjYw==-d+7GOFT9EyCqnKQOQghiczXQAZY29RvdJyi+5gnmR3U=-E+7laPplIOhNh0sd7QwyvQ95LOr6hepvIlQPYS8yTSQ=');
});

test('verify ok', () => {
  const { verify } = createFernetLike({ signerKey, cryptoKey, randomBytes: () => iv, getCurrentDate: () => new Date(1000) });
  const payload = verify('1-61-MTZieXRlc2NjY2NjY2NjYw==-d+7GOFT9EyCqnKQOQghiczXQAZY29RvdJyi+5gnmR3U=-E+7laPplIOhNh0sd7QwyvQ95LOr6hepvIlQPYS8yTSQ=');

  expect(payload).toBe('I want to encrypt this string.');
});

test('verify failure', () => {
  const { verify } = createFernetLike({ signerKey, cryptoKey, randomBytes: () => iv, getCurrentDate: () => new Date(1000) });

  expect(
    () => verify('1-99-MTZieXRlc2NjY2NjY2NjYw==-d+7GOFT9EyCqnKQOQghiczXQAZY29RvdJyi+5gnmR3U=-E+7laPplIOhNh0sd7QwyvQ95LOr6hepvIlQPYS8yTSQ='),
  ).toThrow('Verification failure');
});

test('verify expired', () => {
  const { verify } = createFernetLike({ signerKey, cryptoKey, randomBytes: () => iv, getCurrentDate: () => new Date(1000 + 61 * 1000) });

  expect(
    () => verify('1-61-MTZieXRlc2NjY2NjY2NjYw==-d+7GOFT9EyCqnKQOQghiczXQAZY29RvdJyi+5gnmR3U=-E+7laPplIOhNh0sd7QwyvQ95LOr6hepvIlQPYS8yTSQ='),
  ).toThrow('Expired token');
});
