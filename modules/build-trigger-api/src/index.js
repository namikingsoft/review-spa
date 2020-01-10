console.log('Loading function');

const aws = require('aws-sdk');
const path = require('path');

const s3 = new aws.S3({ apiVersion: '2006-03-01' });

exports.handler = async (event, context) => {
    console.log('Node version:', process.version);
    console.log('Received event:', JSON.stringify(event));
  
    const { archive_base64: archiveBase64 } = JSON.parse(event.body);
    const decode = Buffer.from(archiveBase64, 'base64').toString();

    return {
        statusCode: 200,
        body: dec,
    };
};
