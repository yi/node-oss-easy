# oss-easy

an aliyun oss service client for nodejs, exposes api more like the file system module of Node.JS
一个阿里云 OSS 服务的 Node.JS 模块，提供类似 fs 的 API。同时提供一些方便的批量操作方法

## Documentation

### Init bucekt client instance
```javascript
OssEasy = require("oss-easy")
ossOptions = {
  accessKeyId : "your oss key"
  accessKeySecret : "your oss secret"
}
var oss = new OssEasy(ossOptions, "bucket_name");
```

### Write data to bucket
```javascript
oss.writeFile('remote/path/to/filename', 'content could be string of buffer', function(err) {
    if(err) console.log(err);
});
```

### Upload a local file to bucket
```javascript
oss.uploadFile('path_to_local_file', 'remote/path/to/filename', function(err) {
    if(err) console.log(err);
});
```

### Upload multiple local files to bucket in one batch
```javascript
var tasks = {
  'local/path/to/filename0': "remote/path/to/filename0",
  'local/path/to/filename1': "remote/path/to/filename1",
  'local/path/to/filename2': "remote/path/to/filename2",
};
oss.uploadFiles(tasks, function(err) {
    if(err) console.log(err);
});
```

### Download a file from bucket
```javascript
oss.downloadFile('remote/path/to/filename', 'path_to_local_file', 'function(err) {
    if(err) console.log(err);
});
```

### Download multiple files from bucket
```javascript
var tasks = {
  "remote/path/to/filename0": 'local/path/to/filename0',
  "remote/path/to/filename1": 'local/path/to/filename1',
  "remote/path/to/filename2": 'local/path/to/filename2',
};

oss.downloadFiles(tasks, function(err) {
    if(err) console.log(err);
});
```

### Delete a file from the bucekt
```javascript
oss.deleteFile(filename, function(err) {
    if(err) console.log(err);
});
```

### Delete all remote files under a given folder path
```javascript
oss.deleteFolder('remote/path/to/folder', function(err) {
    if(err) console.log(err);
})
```
### Delete multiple remote files from bucket in one batch
```javascript
oss.deleteFiles(['remote/path/to/filename0','remote/path/to/filename1'], function(err) {
    if(err) console.log(err);
});
```

## Test

```
mocha tests
```


## License
Copyright (c) 2013 yi
Licensed under the MIT license.
