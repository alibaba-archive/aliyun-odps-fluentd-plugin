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
module Fluent
  class ODPSOutput < Fluent::BufferedOutput
    Fluent::Plugin.register_output('aliyun_odps', self)
    @@txt=nil

    def initialize
      super
      require 'time'
      require_relative 'stream_client'
      @compressor = nil
    end

    config_param :path, :string, :default => ""
    config_param :aliyun_access_id, :string, :default => nil
    config_param :aliyun_access_key, :string, :default => nil, :secret => true
    config_param :aliyun_odps_endpoint, :string, :default => nil
    config_param :aliyun_odps_hub_endpoint, :string, :default => nil
    config_param :project, :string, :default => nil
    config_param :format, :string, :default => 'out_file'

    attr_accessor :tables

    unless method_defined?(:log)
      define_method(:log) { $log }
    end
    # TODO: Merge SQLInput's TableElement
    class TableElement
      include Configurable

      config_param :table, :string, :default => nil
      config_param :fields, :string, :default => nil
      config_param :partition, :string, :default => nil
      config_param :num_retries, :integer, :default => 5
      config_param :shard_number, :integer, :default => 1
      config_param :thread_number, :integer, :default => 1
      config_param :time_format, :string, :default => nil 
      config_param :record_batch_size, :integer, :default => 10
      config_param :time_out, :integer, :default => 300
      attr_accessor :partitionList
      attr_reader :client
      attr_reader :writer
      attr_reader :pattern
      attr_reader :log

      def initialize(pattern, log)
        super()
        @pattern = MatchPattern.create(pattern)
        @log = log
        @writer = Array.new
      end

      #初始化数据
      def configure(conf)
        super
        @format_proc = Proc.new { |record|
          values = []
          @fields.split(',').each { |key|
            unless record.has_key?(key)
              @log.warn "the table  "+@table+"'s "+key+" field not has match key"
            end
            values << record[key]
          }
          values
        }
      end

      def init(config)
        odpsConfig = OdpsDatahub::OdpsConfig.new(config[:aliyun_access_id],
                                                 config[:aliyun_access_key],
                                                 config[:aliyun_odps_endpoint],
                                                 config[:aliyun_odps_hub_endpoint],
                                                 config[:project])
        if @shard_number<=0 or @shard_number>5
          raise "the table "+ @table+"'s shard_number is must bewteen 1-5"
        end
        if @record_batch_size<=0
          raise "the table "+ @table+"'s record_batch_size is must more than 0"
        end
        begin
          @client = OdpsDatahub::StreamClient.new(odpsConfig, config[:project], @table)
          @client.loadShard(@shard_number)
          allLoaded = false
          loadtime=0
          while !allLoaded do
            count = 0
            #get json like [{"ShardId": "0","State": "loaded"},{"ShardId": "1","State": "loaded"}]
            @client.getShardStatus.each { |shard|
              if shard["State"] != "loaded"
                sleep(5)
                loadtime+=5
                break
              else
                count += 1
              end
              if count == @shard_number
                allLoaded = true
                @log.info "All shareds are loaded successfully"
              end
              if loadtime>=300
                raise "Load shared timeout"
              end
            }
          end
          for i in 0..@thread_number-1
            @writer[i] = @client.createStreamArrayWriter()
          end
          partitionMaps=@client.getPartitionList
          @partitionList=[]
          for map in partitionMaps do
            partitionName=''
            map.each { |k, v|
              partitionName+=k+"="+v+","
            }
            @partitionList<<partitionName.chomp(",")
          end
        rescue => e
          raise "loadShard failed,"+e.message
        end
      end

      #import data
      def import(chunk)
        records = []
        partitions=Hash.new
        chunk.msgpack_each { |tag, time, data|
          begin
            #if partition is not empty
            unless @partition.blank? then
              #if partition has params in it
              if @partition.include? "=${"
                #split partition
                partition_arrays=@partition.split(',')
                partition_name=''
                i=1
                for p in partition_arrays do
                  #if partition is time formated
                  if p.include? "strftime"
                    key=p[p.index("{")+1, p.index(".strftime")-1-p.index("{")]
                    partition_column=p[0, p.index("=")]
                    timeFormat=p[p.index("(")+2, p.index(")")-3-p.index("(")]
                    if data.has_key?(key)
                      if time_format == nil
                        partition_value=Time.parse(data[key]).strftime(timeFormat)
                      else
                        partition_value=Time.strptime(data[key], time_format).strftime(timeFormat)
                      end
                      if i==1
                        partition_name+=partition_column+"="+partition_value
                      else
                        partition_name+=","+partition_column+"="+partition_value
                      end
                    else
                      raise "partition has no corresponding source key or the partition expression is wrong,"+data
                    end
                  else
                    key=p[p.index("{")+1, p.index("}")-1-p.index("{")]
                    partition_column=p[0, p.index("=")]
                    if data.has_key?(key)
                      partition_value=data[key]
                      if i==1
                        partition_name+=partition_column+"="+partition_value
                      else
                        partition_name+=","+partition_column+"="+partition_value
                      end
                    else
                      raise "partition has no corresponding source key or the partition expression is wrong,"+data
                    end
                  end
                  i+=1
                end
              else
                partition_name=@partition
              end
              if partitions[partition_name]==nil
                partitions[partition_name]=[]
              end
              partitions[partition_name] << @format_proc.call(data)

            else
              records << @format_proc.call(data)
            end

          rescue => e
            raise "Failed to format the data:"+e.message
          end
        }

        begin
          #multi thread
          sendThread = Array.new
          unless @partition.blank? then
            partitions.each { |k, v|
              @log.info k
              #if the partition is not exist, create one
              unless @partitionList.include?(k)
                @client.addPartition(k)
                @partitionList << k
                @log.info "add partition "+k
              end
            }
            for thread in 0..@thread_number-1
              sendThread[thread] = Thread.start(thread) do |threadId|
                retryTime = 0
                begin
                  partitions.each { |k, v|
                    sendCount = v.size/@thread_number
                    restCount = 0
                    if threadId == @thread_number-1
                      restCount = v.size%@thread_number
                    end
                    @writer[threadId].write(v[sendCount*threadId..sendCount*(threadId+1)+restCount-1], k)
                    @log.info "Successfully  import "+(sendCount+restCount).to_s+" data to partition:"+k+",table:"+@table+" at threadId:"+threadId.to_s
                  }
                rescue => e
                  if retryTime > 0
                    @log.info "Fail to write, retry in 2sec. Error at threadId:"+threadId.to_s+" Msg:"+e.message
                    sleep(2)
                    retryTime -= 1
                    retry
                  else
                    raise e
                  end
                end
              end
            end
          else
            @log.info records.size.to_s+" records to be sent"
            for thread in 0..@thread_number-1
              sendThread[thread] = Thread.start(thread) do |threadId|
                retryTime = 0
                #send data from sendCount*threadId to sendCount*(threadId+1)-1
                sendCount = records.size/@thread_number
                restCount = 0
                if threadId == @thread_number-1
                  restCount = records.size%@thread_number
                end
                begin
                  @writer[threadId].write(records[sendCount*threadId..sendCount*(threadId+1)+restCount-1])
                  @log.info "Successfully import "+(sendCount+restCount).to_s+" data to table:"+@table+" at threadId:"+threadId.to_s
                rescue => e
                  if retryTime > 0
                    @log.info "Fail to write, retry in 2sec. Error at threadId:"+threadId.to_s+" Msg:"+e.message
                    sleep(2)
                    retryTime -= 1
                    retry
                  else
                    raise e 
                  end
                end
              end
            end
          end
          for thread in 0..@thread_number-1
            sendThread[thread].join
          end
        rescue => e
          # ignore other exceptions to use Fluentd retry
          raise "write records failed,"+e.message
        end
      end

      def close()
        @client.loadShard(0)
      end

    end

    # This method is called before starting.
    # 'conf' is a Hash that includes configuration parameters.
    # If the configuration is invalid, raise Fluent::ConfigError.
    def configure(conf)
      super
      print "configure"
      # You can also refer raw parameter via conf[name].
      @tables = []
      conf.elements.select { |e|
        e.name == 'table'
      }.each { |e|
        te = TableElement.new(e.arg, log)
        te.configure(e)
        if e.arg.empty?
          log.warn "no table definition"
        else
          @tables << te
        end
      }
      if @tables.empty?
        raise ConfigError, "There is no <table>. <table> is required"
      end
    end

    # This method is called when starting.
    # Open sockets or files here.
    def start
      super
      config = {
          :aliyun_access_id => @aliyun_access_id,
          :aliyun_access_key => @aliyun_access_key,
          :project => @project,
          :aliyun_odps_endpoint => @aliyun_odps_endpoint,
          :aliyun_odps_hub_endpoint => @aliyun_odps_hub_endpoint,
      }
      #初始化各个table object
      @tables.each { |te|
        te.init(config)
      }
      log.info "the table object size is "+@tables.size.to_s
    end

    # This method is called when shutting down.
    # Shutdown the thread and close sockets or files here.
    def shutdown
      super
      @tables.reject! do |te|
        te.close()
      end
    end

    # This method is called when an event reaches to Fluentd.
    # Convert the event to a raw string.
    def format(tag, time, record)
      [tag, time, record].to_json + "\n"
    end

    # This method is called every flush interval. Write the buffer chunk
    # to files or databases here.
    # 'chunk' is a buffer chunk that includes multiple formatted
    # events. You can use 'data = chunk.read' to get all events and
    # 'chunk.open {|io| ... }' to get IO objects.
    #
    # NOTE! This method is called by internal thread, not Fluentd's main thread. So IO wait doesn't affect other plugins.
    def write(chunk)
      #foreach tables，choose table oject ,data = chunk.read
      @tables.each { |table|
        if table.pattern.match(chunk.key)
          log.info "Begin to import the data and the table_match is "+chunk.key
          return table.import(chunk)
        end
      }
    end

    def emit(tag, es, chain)
      super(tag, es, chain, format_tag(tag))
    end

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def format_tag(tag)
      if @remove_tag_prefix
        tag.gsub(@remove_tag_prefix, '')
      else
        tag
      end
    end
  end
end
