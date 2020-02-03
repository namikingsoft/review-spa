const createFernetLike = require('./fernetLike');

const signerKey = '16bytesaaaaaaaaa';
const cryptoKey = '16bytesbbbbbbbbb';
const iv = Buffer.from('16bytesccccccccc');
const unixtime = 1580000000 * 1000;

test('sign', () => {
  const { sign } = createFernetLike({ signerKey, cryptoKey, randomBytes: () => iv, getCurrentDate: () => new Date(unixtime) });
  const token = sign('I want to encrypt this string.', 60);

  expect(token).toBe('1-5e2ce33c-MTZieXRlc2NjY2NjY2NjYw==-d+7GOFT9EyCqnKQOQghiczXQAZY29RvdJyi+5gnmR3U=-22v7OypcYx0N9kS3WQ6wI0X1Y73JDOOn3DXIUldU/j8=');
});

test('verify ok', () => {
  const { verify } = createFernetLike({ signerKey, cryptoKey, randomBytes: () => iv, getCurrentDate: () => new Date(unixtime) });
  const payload = verify('1-5e2ce33c-MTZieXRlc2NjY2NjY2NjYw==-d+7GOFT9EyCqnKQOQghiczXQAZY29RvdJyi+5gnmR3U=-22v7OypcYx0N9kS3WQ6wI0X1Y73JDOOn3DXIUldU/j8=');

  expect(payload).toBe('I want to encrypt this string.');
});

test('verify failure', () => {
  const { verify } = createFernetLike({ signerKey, cryptoKey, randomBytes: () => iv, getCurrentDate: () => new Date(unixtime) });

  expect(
    () => verify('1-ffffffff-MTZieXRlc2NjY2NjY2NjYw==-d+7GOFT9EyCqnKQOQghiczXQAZY29RvdJyi+5gnmR3U=-22v7OypcYx0N9kS3WQ6wI0X1Y73JDOOn3DXIUldU/j8='),
  ).toThrow('Verification failure');
});

test('verify expired', () => {
  const { verify } = createFernetLike({ signerKey, cryptoKey, randomBytes: () => iv, getCurrentDate: () => new Date(unixtime + 61 * 1000) });

  expect(
    () => verify('1-5e2ce33c-MTZieXRlc2NjY2NjY2NjYw==-d+7GOFT9EyCqnKQOQghiczXQAZY29RvdJyi+5gnmR3U=-22v7OypcYx0N9kS3WQ6wI0X1Y73JDOOn3DXIUldU/j8='),
  ).toThrow('Expired token');
});
