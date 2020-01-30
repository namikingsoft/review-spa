const createFernetLike = require('./fernetLike');

const signerKey = '16bytesaaaaaaaaa';
const cryptoKey = 'decent-long-string-bbb';
const salt = 'decent-long-string-ccc';

test('sign', () => {
  const { sign } = createFernetLike({ signerKey, cryptoKey, salt, getCurrentDate: () => new Date(1000) });
  const token = sign('I want to encrypt this string.', 60);

  expect(token).toBe('flv1-61-rvrtDSwoKi0z8SB/2dTdUn38BUEl4mKFZVtpfGd9B3o=-M8/Ylt0x6Ukp2tn/aG7+j98q/C/HJOMuFlp7UqvGs34=');
});

test('verify ok', () => {
  const { verify } = createFernetLike({ signerKey, cryptoKey, salt, getCurrentDate: () => new Date(1000) });
  const payload = verify('flv1-61-rvrtDSwoKi0z8SB/2dTdUn38BUEl4mKFZVtpfGd9B3o=-M8/Ylt0x6Ukp2tn/aG7+j98q/C/HJOMuFlp7UqvGs34=');

  expect(payload).toBe('I want to encrypt this string.');
});

test('verify failure', () => {
  const { verify } = createFernetLike({ signerKey, cryptoKey, salt, getCurrentDate: () => new Date(1000) });

  expect(
    () => verify('flv1-777-rvrtDSwoKi0z8SB/2dTdUn38BUEl4mKFZVtpfGd9B3o=-M8/Ylt0x6Ukp2tn/aG7+j98q/C/HJOMuFlp7UqvGs34='),
  ).toThrow('Verification failure');
});

test('verify expired', () => {
  const { verify } = createFernetLike({ signerKey, cryptoKey, salt, getCurrentDate: () => new Date(1000 + 61 * 1000) });

  expect(
    () => verify('flv1-61-rvrtDSwoKi0z8SB/2dTdUn38BUEl4mKFZVtpfGd9B3o=-M8/Ylt0x6Ukp2tn/aG7+j98q/C/HJOMuFlp7UqvGs34='),
  ).toThrow('Expired token');
});
