console.log('Loading function');

const aws = require('aws-sdk');
const path = require('path');
const https = require('https');

const s3 = new aws.S3({ apiVersion: '2006-03-01' });

const {
    tempArchiveBucketName,
    tempArchiveDomainName,
    circleCIPersonalToken,
} = process.env;

const pipelineEndpoint = 'https://circleci.com/api/v2/project/gh/namikingsoft/review-for-spa/pipeline';
const optionsForPostJSON = {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
    },
    auth: `${circleCIPersonalToken}:`
};

const triggerCreateReviewApp = payload => new Promise((resolve, reject) => {
    console.log('start trigger');
    const req = https.request(
        pipelineEndpoint,
        optionsForPostJSON,
        res => {
            console.log('statusCode:', res.statusCode);
            console.log('headers:', res.headers);
            res.on('data', data => {
                process.stdout.write(data);
            });
            res.on('end', () => {
                console.log('finish trigger');
                resolve();
            });
        },
    );

    req.on('error', err => {
        reject(err);
    });
    req.write(JSON.stringify(payload));
    req.end();
});

exports.handler = async (event, context) => {
    console.log('Node version:', process.version);
    console.log('Received event:', JSON.stringify(event));
  
    const payload = JSON.parse(event.body);
    const { archive_base64: archiveBase64 } = payload;

    const archiveBuffer = Buffer.from(archiveBase64, 'base64');
    const archiveFilename = `${new Date().getTime()}.tar.gz`;

    const updateParams = {
        Bucket: tempArchiveBucketName,
        Key: archiveFilename,
        Body: archiveBuffer,
    };

    await s3.upload(updateParams).promise();

    await triggerCreateReviewApp({
        parameters: {
            ...payload,
            create_review_app: true,
            archive_url: `https://${tempArchiveDomainName}/${archiveFilename}`,
        },
    });

    return {
        statusCode: 200,
        body: 'OK',
    };
};