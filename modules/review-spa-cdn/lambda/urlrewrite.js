console.log('Loading function');

const path = require('path');
const aws = require('aws-sdk');

const createFernetLike = require('./fernetlike');
const jsonRequest = require('./jsonRequest');
const env = require('./.env.json');

console.log('Environments:', JSON.stringify(env));

const {
    s3OriginBucketName,
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

const parseQueryString = querystring => querystring
    .split('&')
    .map(x => x.split('='))
    .reduce((acc, [key, val]) => ({ ...acc, [key]: decodeURIComponent(val) }), {});

const parseSubdomain = subdomain => {
    const xs = subdomain.split('--');
    const identifier = xs.shift();
    const username = xs.pop();
    const reponame = xs.join('--');
    return { identifier, username, reponame };
};

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
    const [, subdomain] = host.match(/^([^\.]+)\./);
    const originalUrl = `https://${host}${request.uri}`;

    // Parse cookie headers
    const cookie = cookieHeaders ? cookieHeaders
        .map(({ value }) => value)
        .reduce((acc, x) => [...acc, ...x.split(';')], [])
        .map(x => x.trim().split('='))
        .reduce((acc, [name, ...value]) => ({ ...acc, [name]: value.join('=')}), {})
        : {};
    console.log('Cookie:', JSON.stringify(cookie));

    if (subdomain === 'auth') {
        try {
            const { code, state } = parseQueryString(querystring);
            const { subdomain, redirectUri, settings } = JSON.parse(verify(state));
            const { username, reponame } = parseSubdomain(subdomain);
            const { access_token: githubAccessToken } = JSON.parse(
                await jsonRequest({
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
                await jsonRequest({
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
            return {
                status: '302',
                statusDescription: 'Found',
                headers: {
                    location: [{
                        key: 'Location',
                        value: `${redirectUri}?${cdnTokenName}=${encodeURIComponent(cdnToken)}`,
                    }],
                },
            };
        } catch (err) {
            console.log('Unauthorized:', err.stack || err);
            return {
                status: '401',
                statusDescription: 'Unauthorized',
                body: '401 Unauthorized',
            };
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
            return {
                status: '302',
                statusDescription: 'Found',
                headers: {
                    location: [{
                        key: 'Location',
                        value: originalUrl,
                    }],
                    'set-cookie': [{
                        key: 'Set-Cookie',
                        value: `${cdnTokenName}=${cdnToken}; path=/; Max-Age=${cdnTokenMaxAge}; SameSite=Lax; Secure; HttpOnly`,
                    }],
                },
            };
        }
    }

    console.log('Auth token not found');

    const settings = await loadSettings(subdomain);
    const { useGitHubOAuth } = settings;
    if (useGitHubOAuth) {
        const stateMaxAge = 3600; // 1 hour
        const state = sign(JSON.stringify({ subdomain, redirectUri: originalUrl, settings }), stateMaxAge);
        return {
            status: '302',
            statusDescription: 'Found',
            headers: {
                location: [{
                    key: 'Location',
                    value: `https://github.com/login/oauth/authorize?client_id=${githubOAuthClientId}&scope=repo_deployment&state=${state}`,
                }],
                'set-cookie': [{
                    key: 'Set-Cookie',
                    value: `${cdnTokenName}=; path=/; Max-Age=0; SameSite=Lax; Secure; HttpOnly`,
                }],
            },
        };
    }

    const cdnToken = sign(JSON.stringify({ settings }), cdnTokenMaxAge);
    return {
        status: '302',
        statusDescription: 'Found',
        headers: {
            location: [{
                key: 'Location',
                value: originalUrl,
            }],
            'set-cookie': [{
                key: 'Set-Cookie',
                value: `${cdnTokenName}=${cdnToken}; path=/; Max-Age=${cdnTokenMaxAge}; SameSite=Lax; Secure; HttpOnly`,
            }],
        },
    };
}
