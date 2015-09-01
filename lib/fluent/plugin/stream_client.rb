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
require 'json'
require_relative 'exceptions'
require_relative 'stream_writer'
require_relative 'stream_reader'
require_relative 'http/http_connection'
require_relative 'conf/config'
require_relative 'odps/odps_table'

module OdpsDatahub
  class StreamClient
    attr_reader :mProject, :mTable, :mOdpsConfig, :mOdpsTableSchema, :mOdpsTable
    def initialize(odpsConfig, project, table)
      @mOdpsConfig = odpsConfig
      @mProject = project
      @mTable = table
      @mShards = Array.new
      if @mProject == nil or @mProject == ""
        @mProject = @mOdpsConfig.defaultProjectName
      end
      @mOdpsTable = OdpsTable.new(@mOdpsConfig, @mProject, @mTable)
      header = Hash.new
      param = Hash.new
      param[$PARAM_QUERY] = "meta"
      conn = HttpConnection.new(@mOdpsConfig, header, param, getResource, "GET")
      res = conn.getResponse
      jsonTableMeta = JSON.parse(res.body)
      if res.code != "200"
        raise OdpsDatahubException.new(jsonTableMeta["Code"], "initialize failed because " + jsonTableMeta["Message"])
      end
      @mOdpsTableSchema = OdpsTableSchema.new(jsonTableMeta["Schema"])
    end

    #get partitions and return an array like :[{"time"=>"2016", "place"=>"china2"},{"time"=>"2015", "place"=>"china"}]
    def getPartitionList
      @mOdpsTable.getPartitionList
    end

    #ptStr ex: 'dt=20150805,hh=08,mm=24'
    #call add partiton if not exsits
    def addPartition(ptStr)
      @mOdpsTable.addPartition(ptStr)
    end

    def getOdpsTableSchema
      return @mOdpsTableSchema
    end

    def createStreamWriter(shardId = nil)
      StreamWriter.new(@mOdpsConfig, @mProject, @mTable,getResource, shardId)
    end

    def createStreamArrayWriter(shardId = nil)
      StreamWriter.new(@mOdpsConfig, @mProject, @mTable,getResource, shardId,  @mOdpsTableSchema)
    end

    #return json like [{"ShardId": "0","State": "loaded"},{"ShardId": "1","State": "loaded"}]
    def getShardStatus
      header = Hash.new
      param = Hash.new
      param[$PARAM_CURR_PROJECT] = @mProject
      param[$PARAM_SHARD_STATUS] = ""

      conn = HttpConnection.new(@mOdpsConfig, header, param, getResource + "/shards", "GET")
      res = conn.getResponse
      json_obj = JSON.parse(res.body)
      if res.code != "200"
        raise OdpsDatahubException.new(json_obj["Code"], "getShardStatus failed because " + json_obj["Message"])
      end
      return json_obj["ShardStatus"]
    end

    def loadShard(idx)
      if idx < 0
        raise OdpsDatahubException.new($INVALID_ARGUMENT, "loadShard num invalid")
      end
      header = Hash.new
      param = Hash.new
      param[$PARAM_CURR_PROJECT] = @mProject
      param[$PARAM_SHARD_NUMBER] = idx
      conn = HttpConnection.new(@mOdpsConfig, header, param, getResource + "/shards", "POST")
      res = conn.getResponse
      if res.code != "200"
        json_obj = JSON.parse(res.body)
        raise OdpsDatahubException.new(json_obj["Code"], "loadShard failed because " + json_obj["Message"])
      end
    end

    protected
    def getResource
      return "/projects/" + @mProject + "/tables/" + @mTable
    end
  end
end
