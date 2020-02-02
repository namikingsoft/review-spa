const { responseOf302Found, responseOf401Unauthorized } = require('./responseEvent');

const signerKey = '16bytesaaaaaaaaa';
const cryptoKey = 'decent-long-string-bbb';
const salt = 'decent-long-string-ccc';

describe('responseOf302Found', () => {
  test('only redirect', () => {
    expect(
      responseOf302Found({
        redirectUrl: 'https://example.com/index.html',
      }),
    ).toEqual({
      status: 302,
      statusDescription: 'Found',
      headers: {
        location: [{
          key: 'Location',
          value: 'https://example.com/index.html',
        }],
      },
    });
  });

  test('set cookie', () => {
    expect(
      responseOf302Found({
        redirectUrl: 'https://example.com/index.html',
        setCookie: {
          name: 'token',
          value: 'asdfqwer',
        }
      }),
    ).toEqual({
      status: 302,
      statusDescription: 'Found',
      headers: {
        location: [{
          key: 'Location',
          value: 'https://example.com/index.html',
        }],
        'set-cookie': [{
          key: 'Set-Cookie',
          value: `token=asdfqwer; path=/; SameSite=Lax; Secure; HttpOnly`,
        }],
      },
    });
  });

  test('set cookie having max-age', () => {
    expect(
      responseOf302Found({
        redirectUrl: 'https://example.com/index.html',
        setCookie: {
          name: 'token',
          value: 'asdfqwer',
          maxAge: 86400,
        }
      }),
    ).toEqual({
      status: 302,
      statusDescription: 'Found',
      headers: {
        location: [{
          key: 'Location',
          value: 'https://example.com/index.html',
        }],
        'set-cookie': [{
          key: 'Set-Cookie',
          value: `token=asdfqwer; path=/; Max-Age=86400; SameSite=Lax; Secure; HttpOnly`,
        }],
      },
    });
  });

  test('remove cookie', () => {
    expect(
      responseOf302Found({
        redirectUrl: 'https://example.com/index.html',
        setCookie: {
          name: 'token',
          maxAge: 0,
        }
      }),
    ).toEqual({
      status: 302,
      statusDescription: 'Found',
      headers: {
        location: [{
          key: 'Location',
          value: 'https://example.com/index.html',
        }],
        'set-cookie': [{
          key: 'Set-Cookie',
          value: `token=; path=/; Max-Age=0; SameSite=Lax; Secure; HttpOnly`,
        }],
      },
    });
  });
});

describe('responseOf401Unauthorized', () => {
  test('default', () => {
    expect(
      responseOf401Unauthorized(),
    ).toEqual({
      status: '401',
      statusDescription: 'Unauthorized',
      body: '401 Unauthorized',
    });
  });
});
