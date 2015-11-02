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
require 'net/http'
require 'stringio'
require 'digest/md5'
require 'zlib'
require_relative 'exceptions'
require_relative 'http/http_connection'
require_relative 'serialize/serializer'
require_relative 'conf/config'
require_relative 'odps/xstream_pack.pb'
require_relative 'odps/odps_table'

module OdpsDatahub
  class StreamWriter
    attr_reader :mRecordList, :mProject, :mTable, :mPath, :mShardId, :mUpStream, :mOdpsConfig
    def initialize(odpsConfig, project, table, path, shardId = nil, odpsSchema = nil)
      @mOdpsConfig = odpsConfig
      @mProject = project
      @mTable = table
      @mPath = path
      @mShardId = shardId
      @mSchema = odpsSchema
      reload
    end

    def reload
      @mUpStream = ::StringIO.new
      @mRecordList = Array.new
      @mUpStream.set_encoding(::Protobuf::Field::BytesField::BYTES_ENCODING)
    end

    def write(recordList, partition = "")
      if recordList.is_a?Array
        recordList.each{ |value|
          #handle RecordList
          if value.is_a?OdpsTableRecord
            @mRecordList.push(value)
          #handle ArrayList
          elsif value.is_a?Array and @mSchema != nil and value.size == @mSchema.getColumnCount
            record = convert2Record(value)
            @mRecordList.push(record)
          else
            raise OdpsDatahubException.new($INVALID_ARGUMENT, "write an error type")
          end
        }
      else
        raise OdpsDatahubException.new($INVALID_ARGUMENT, "write param must be a array")
      end

      serializer = Serializer.new
      serializer.serialize(@mUpStream, @mRecordList)

      if @mUpStream.length == 0
        raise OdpsDatahubException.new($INVALID_ARGUMENT, "mRecordList is empty")
      end
      header = Hash.new
      param = Hash.new
      param[$PARAM_CURR_PROJECT] = @mProject
      #TODO partition format
      param[$PARAM_PARTITION] = partition
      param[$PARAM_RECORD_COUNT] = @mRecordList.size.to_s
      header[$CONTENT_ENCODING] = "deflate"
      header[$CONTENT_TYPE] = "application/octet-stream"
=begin version 4
      pack = OdpsDatahub::XStreamPack.new
      pack.pack_data = Zlib::Deflate.deflate(@mUpStream.string)
      pack.pack_meta = ""
      upstream = ::StringIO.new
      pack.serialize_to(upstream)
      header[$CONTENT_MD5] = Digest::MD5.hexdigest(upstream.string)
      header[$CONTENT_LENGTH] = upstream.length.to_s

      conn = HttpConnection.new(@mOdpsConfig, header, param, @mPath + "/shards/" + @mShardId.to_s, "PUT", upstream)
=end
      #version 3
      upStream = Zlib::Deflate.deflate(@mUpStream.string)
      header[$CONTENT_MD5] = Digest::MD5.hexdigest(upStream)
      header[$CONTENT_LENGTH] = upStream.length.to_s
      #MAX_LENGTH 2048KB
      if upStream.length > $MAX_PACK_SIZE
        raise OdpsDatahubException.new($PACK_SIZE_EXCEED, "pack size:" + upStream.length.to_s)
      end
      if @mShardId != nil
        conn = HttpConnection.new(@mOdpsConfig, header, param, @mPath + "/shards/" + @mShardId.to_s, "PUT", upStream)
      else
        conn = HttpConnection.new(@mOdpsConfig, header, param, @mPath + "/shards", "PUT", upStream)
      end

      reload
      res = conn.getResponse
      json_obj = JSON.parse(res.body)
      if res.code != "200"
        raise OdpsDatahubException.new(json_obj["Code"], "write failed because " + json_obj["Message"])
      end
    end

    private
    def convert2Record(value)
      if not value.is_a?Array
        raise OdpsDatahubException.new($INVALID_ARGUMENT, "param for convert2Record must be a array")
      end

      if value.count != @mSchema.getColumnCount
        raise OdpsDatahubException.new($SCHEMA_NOT_MATCH, "column counts are not equal between value and schema")
      end

      record = OdpsTableRecord.new(@mSchema)
      i = 0
      while i < value.count do
        type = @mSchema.getColumnType(i)
        if value[i] == nil
          record.setNullValue(i)
          i += 1
          next
        end
        case type
          when $ODPS_BIGINT
            record.setBigInt(i, value[i])
          when $ODPS_BOOLEAN
            record.setBoolean(i, value[i])
          when $ODPS_DATETIME
            record.setDateTime(i, value[i])
          when $ODPS_DOUBLE
            record.setDouble(i, value[i])
          when $ODPS_STRING
            record.setString(i, value[i])
          when $ODPS_DECIMAL
            record.setDecimal(i, value[i])
          else
            raise OdpsDatahubException.new($INVALID_ARGUMENT, "unsupported schema type")
        end
        i += 1
      end
      return record
    end
  end
end