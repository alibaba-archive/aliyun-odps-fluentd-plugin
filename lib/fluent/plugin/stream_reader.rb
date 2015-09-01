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
require_relative 'http/http_connection'
require_relative 'serialize/deserializer'
require_relative 'conf/config'
require_relative 'odps/xstream_pack.pb'
require_relative 'odps/odps_table'

module OdpsDatahub
  class StreamReader
    attr_reader :mProject, :mTable, :mPath, :mShardId, :mPackId, :mReadMode, :mSchema, :mPackStream
    def initialize(project, table, shardId, path, schema, packId = PackType.FIRST_PACK_ID)
      @mProject = project
      @mTable = table
      @mPath = path
      @mShardId = shardId
      @mSchema = schema
      @mPackId = packId
      @mReadMode = ReadMode.SEEK_BEGIN
    end
    #TODO
    def read #return a pack stream of this pack
      if mPackStream != nil
        mPackStream = getPack
      end

    end
    #TODO
    def getPack #get cur pack stream

    end
  end
end