# oss-easy

an aliyun oss service client for nodejs, exposes api more like the file system module of Node.JS

## Getting Started
Install the module with: `npm install oss-easy`

```javascript
var oss_easy = require('oss-easy');
var oss = oss_easy.init("oss_key", "oss_secret", "bucket_name");
```

## Documentation

### Init and get bucekt client instance
```javascript
var oss = oss_easy.init("oss_key", "oss_secret", "bucket_name");
```

### Write data to bucket
```javascript
oss.writeFile('filename', 'content could be string of buffer', function(err) {
    if(err) console.log(err);
});
```

### Upload a local file to bucket
```javascript
oss.uploadFile('filename', 'path_to_local_file', function(err) {
    if(err) console.log(err);
});
```

### Upload multiple local files to bucket in one batch
```javascript
oss.uploadFileBatch(['local_file_name0', 'local_file_name1'], "path_to_local_folder", function(err) {
    if(err) console.log(err);
});
```

### Delete a file from the bucekt
```javascript
oss.deleteFile(filename, function(err) {
    if(err) console.log(err);
});
```

### Delete multiple remote files from bucket in one batch
```javascript
oss.deleteFileBatch(['remote_file_name0','remote_file_name1'], function(err) {
    if(err) console.log(err);
});
```

## License
Copyright (c) 2013 yi
Licensed under the MIT license.
