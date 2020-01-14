console.log('Loading function');

const path = require('path')

exports.handler = (event, context, callback) => {
    console.log('Node version:', process.version);
    console.log('Received event:', JSON.stringify(event));

    const { Records: [{ cf: { request } }] } = event;
    if (!path.extname(request.uri)) {
        request.uri = '/index.html';
    }

    const { headers: { host: [{ value: host }]}} = request;
    const matches = host.match(/^([^\.]+)\./);
    if (matches) {
        request.uri = `/${matches[1]}${request.uri}`;
    }

    callback(null, request);
}
