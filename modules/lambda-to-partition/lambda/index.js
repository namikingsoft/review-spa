console.log('Loading function');

const aws = require('aws-sdk');
const path = require('path');

const s3 = new aws.S3({ apiVersion: '2006-03-01' });

exports.handler = async (event, context) => {
  console.log('Node version:', process.version);
  console.log('Received event:', JSON.stringify(event));

  const s3Promises = event.Records.map(async record => {
    // S3 イベントのみ処理
    if (record.s3 == undefined) return;
    const bucket = record.s3.bucket.name;
    const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
    console.log('bucket', bucket);
    console.log('key', key);

    // この関数でコピーしたファイルはスキップ
    // 念の為、イベントのフィルターで PUT 以外は発動しないようにする
    if (key.match(/dt=/)) {
      console.log('Skip partition');
      return;
    }

    // ファイル名の日付をパース
    const matches = key.match(/\.(\d{4}-\d{2}-\d{2})[^\/]+\.gz$/);
    if (!matches) {
      throw new Error('Not log file');
    }

    // S3 copyObject API で Hive 形式ディレクトリにコピー
    const prefix = key.includes('/') ? `${path.dirname(key)}/` : '';
    const basename = path.basename(key);
    const copyKeyPath = `${prefix}dt=${matches[1]}/${basename}`;
    const params = {
      Bucket: bucket,
      CopySource: `${bucket}/${key}`,
      Key: copyKeyPath,
    };
    console.log('Copy to partition:', JSON.stringify(params));
    return s3.copyObject(params).promise();
  });

  await Promise.all(s3Promises);
};
