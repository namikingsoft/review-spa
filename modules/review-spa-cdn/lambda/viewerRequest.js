console.log('Loading function');

const path = require('path');
const aws = require('aws-sdk');

const createFernetLike = require('./fernetLike');
const jsonFetch = require('./jsonFetch');
const { responseOf302Found, responseOf401Unauthorized } = require('./responseEvent');

const env = require('./.env.json');
console.log('Environments:', JSON.stringify(env));

const {
  s3OriginBucketName,
  wildcardDomain,
  cdnTokenName,
  cdnTokenMaxAge,
  cdnSettingsJsonFilename,
  githubOAuthClientId,
  githubOAuthClientSecret,
  signerKey,
  cryptoKey,
  salt,
} = env;

const s3 = new aws.S3({ apiVersion: '2006-03-01' });
const { sign, verify } = createFernetLike({ signerKey, cryptoKey, salt });

// TODO: environment
const authSubdomain = 'auth';

const parseQueryString = querystring => querystring
  .split('&')
  .map(x => x.split('='))
  .reduce((acc, [key, val]) => ({ ...acc, [key]: decodeURIComponent(val) }), {});

const loadSettings = async subdomain => {
  try {
    const settingKey = `${subdomain}/${cdnSettingsJsonFilename}`;
    const data = await s3.getObject({ Bucket: s3OriginBucketName, Key: settingKey }).promise();
    return JSON.parse(String(data.Body));
  } catch (err) {
    return { useGitHubOAuth: false };
  }
};

exports.handler = async (event, context) => {
  console.log('Node version:', process.version);
  console.log('Received event:', JSON.stringify(event));

  const { Records: [{ cf: { request } }] } = event;
  const { headers: { host: [{ value: host }], cookie: cookieHeaders }, querystring } = request;
  const [subdomain] = host.split('.');
  const originalUrl = `https://${host}${request.uri}`;

  // Parse cookie headers
  const cookie = cookieHeaders ? cookieHeaders
    .map(({ value }) => value)
    .reduce((acc, x) => [...acc, ...x.split(';')], [])
    .map(x => x.trim().split('='))
    .reduce((acc, [name, ...value]) => ({ ...acc, [name]: value.join('=') }), {})
    : {};
  console.log('Cookie:', JSON.stringify(cookie));

  if (subdomain === authSubdomain) {
    try {
      const { code, state } = parseQueryString(querystring);
      const { redirectUri, settings } = JSON.parse(verify(state));
      const { username, reponame } = settings;
      const { access_token: githubAccessToken } = JSON.parse(
        await jsonFetch({
          method: 'POST',
          url: 'https://github.com/login/oauth/access_token',
          body: JSON.stringify({
            code,
            state,
            client_id: githubOAuthClientId,
            client_secret: githubOAuthClientSecret,
          }),
        }),
      );
      const deployments = JSON.parse(
        await jsonFetch({
          url: `https://api.github.com/repos/${username}/${reponame}/deployments`,
          headers: {
            'Authorization': `token ${githubAccessToken}`,
            'User-Agent': 'request',
          },
        }),
      );
      if (isNaN(deployments.length)) {
        throw new Error('Unauthorize repository');
      }
      const cdnToken = sign(JSON.stringify({ settings }), cdnTokenMaxAge);
      return responseOf302Found({
        redirectUrl: `${redirectUri}?${cdnTokenName}=${encodeURIComponent(cdnToken)}`,
      });
    } catch (err) {
      console.log('Unauthorized:', err.stack || err);
      return responseOf401Unauthorized();
    }
  }

  if (cookie[cdnTokenName]) {
    try {
      verify(cookie[cdnTokenName]);

      if (!path.extname(request.uri)) {
        request.uri = '/index.html';
      }
      request.uri = `/${subdomain}${request.uri}`;

      return request;
    } catch (err) {
      console.log('Failed Verification:', err.stack || err);
    }
  } else {
    const { [cdnTokenName]: cdnToken } = parseQueryString(querystring);
    if (cdnToken) {
      console.log('Set auth token to cookie:', cdnToken)
      return responseOf302Found({
        redirectUrl: originalUrl,
        setCookie: {
          name: cdnTokenName,
          value: cdnToken,
          maxAge: cdnTokenMaxAge,
        },
      });
    }
  }

  console.log('Auth token not found');

  const settings = await loadSettings(subdomain);
  const { useGitHubOAuth } = settings;
  if (useGitHubOAuth) {
    const stateMaxAge = 3600; // 1 hour
    const state = sign(JSON.stringify({ redirectUri: originalUrl, settings }), stateMaxAge);
    return responseOf302Found({
      redirectUrl: `https://github.com/login/oauth/authorize?client_id=${githubOAuthClientId}&scope=repo_deployment&state=${state}`,
      setCookie: { name: cdnTokenName },
    });
  }

  const cdnToken = sign(JSON.stringify({ settings }), cdnTokenMaxAge);
  return responseOf302Found({
    redirectUrl: originalUrl,
    setCookie: {
      name: cdnTokenName,
      value: cdnToken,
      maxAge: cdnTokenMaxAge,
    },
  });
}
