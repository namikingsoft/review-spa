const https = require("https");

const jsonFetch = ({ url, body, method = 'GET', headers: overwriteHeaders }) => new Promise((resolve, reject) => {
  const headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Content-Length': body ? body.length : 0,
    ...overwriteHeaders,
  };
  console.log('request:', JSON.stringify({ method, url, body, headers }));
  var req = https.request(url, { method, headers }, res => {
    console.log('statusCode:', res.statusCode);
    console.log('headers:', res.headers);
    let xBody = '';
    res.on('data', x => xBody += x);
    res.on('end', () => {
      console.log('body', xBody);
      resolve(xBody);
    });
  });
  if (body) req.write(body);
  req.on('error', reject);
  req.end();
});

module.exports = jsonFetch;
