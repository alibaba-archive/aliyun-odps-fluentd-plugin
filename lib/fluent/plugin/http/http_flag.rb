#
#Licensed to the Apache Software Foundation (ASF) under one
#or more contributor license agreements.  See the NOTICE file
#distributed with this work for additional information
#regarding copyright ownership.  The ASF licenses this file
#to you under the Apache License, Version 2.0 (the
#"License"); you may not use this file except in compliance
#with the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing,
#software distributed under the License is distributed on an
#"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#KIND, either express or implied.  See the License for the
#specific language governing permissions and limitations
#under the License.
#
module OdpsDatahub
  $SDK_UA_STR = "ODPS Ruby SDK v0.1"
  $MAX_PACK_SIZE = 2048*10*1024
  class HttpHeaders
    $AUTHORIZATION = "Authorization"
    $CACHE_CONTROL = "Cache-Control"
    $CONTENT_DISPOSITION = "Content-Disposition"
    $CONTENT_ENCODING = "Content-Encoding"
    $CONTENT_LENGTH = "Content-Length"
    $CONTENT_MD5 = "Content-MD5"
    $CONTENT_TYPE = "Content-Type"
    $DATE = "Date"
    $ETAG = "ETag"
    $EXPIRES = "Expires"
    $HOST = "Host"
    $LAST_MODIFIED = "Last-Modified"
    $RANGE = "Range"
    $LOCATION = "Location"
    $TRANSFER_ENCODING = "Transfer-Encoding"
    $CHUNKED = "chunked"
    $ACCEPT_ENCODING = "Accept-Encoding"
    $USER_AGENT = "User-Agent"
    $TUNNEL_VERSION = "x-odps-tunnel-version"
    $TUNNEL_STREAM_VERSION = "x-odps-tunnel-stream-version"
  end
  class HttpParam
    $PARAM_RECORD_COUNT = "recordcount"
    $PARAM_PACK_ID = "packid"
    $PARAM_PACK_NUM = "packnum"
    $PARAM_ITERATE_MODE = "iteratemode"
    $PARAM_ITER_MODE_AT_PACKID = "AT_PACKID"
    $PARAM_ITER_MODE_AFTER_PACKID = "AFTER_PACKID"
    $PARAM_ITER_MODE_FIRST_PACK = "FIRST_PACK"
    $PARAM_ITER_MODE_LAST_PACK = "LAST_PACK"
    $PARAM_SHARD_NUMBER = "shardnumber"
    $PARAM_SHARD_STATUS = "shardstatus"
    $PARAM_PARTITION = "partition"
    $PARAM_PARTITIONS = "partitions"
    $PARAM_SEEK_TIME = "timestamp"
    $PARAM_CURR_PROJECT = "curr_project"
    $PARAM_TYPE = "type"
    $PARAM_QUERY = "query"
    $PARAM_EXPECT_MARKER = "expectmarker"
    $PARAM_MARKER = "marker"
  end
  class PackType
    @@FIRST_PACK_ID = "00000000000000000000000000000000"
  end
  class ReadMode
    @@SEEK_BEGIN = 1
    @@SEEK_END = 2
    @@SEEK_CUR = 3
    @@SEEK_NEXT = 4
  end
end
