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

require 'rexml/document'
require_relative 'xml_template'
require_relative 'odps_table_schema'
require_relative '../http/http_connection'

module OdpsDatahub
  $STRING_MAX_LENTH = 8 * 1024 * 1024
  $DATETIME_MAX_TICKS = 253402271999000
  $DATETIME_MIN_TICKS = -62135798400000
  $STRING_CHARSET = "UTF-8"
  class OdpsTableRecord
    attr_reader :mValues, :mSchema

    def initialize(schema)
      @mSchema = schema
      @mValues = Array.new(@mSchema.getColumnCount)
    end

    def getColumnsCount
      @mSchema.getColumnCount
    end

    def getTableSchema
      @mSchema
    end

    def getValue(idx)
      if idx < 0 or idx >= @mSchema.getColumnCount
        raise "idx out of range"
      end
      @mValues.at(idx)
    end

    def setNullValue(idx)
      setValue(idx, nil)
    end

    def setBigInt(idx, value)
      if value.is_a?Integer
        setValue(idx, value)
      elsif value.is_a?String
        setValue(idx, value.to_i)
      else
        raise "value show be Integer, idx:" + idx.to_s + " value:" + value.to_s
      end
    end

    def setDouble(idx, value)
      if value.is_a?Float
        setValue(idx, value)
      elsif value.is_a?String
        setValue(idx, value.to_f)
      else
        raise "value show be Float, idx:" + idx.to_s + " value:" + value.to_s
      end
    end

    def setBoolean(idx, value)
      if value.is_a?String
        if value == "true"
          setValue(idx, true)
        elsif value == "false"
          setValue(idx, false)
        else
          raise "value must be true or false, idx:" + idx.to_s + " value:" + value.to_s
        end
      elsif value != false and value != true
        raise "value must be bool or string[true,false], idx:" + idx.to_s + " value:" + value.to_s
      end
      setValue(idx, value)
    end

    def setDateTime(idx, value)
      if value.is_a?Integer and value >= $DATETIME_MIN_TICKS and  value <= $DATETIME_MAX_TICKS
        setValue(idx, value)
      elsif value.is_a?DateTime or value.is_a?Time
        if value.to_i*1000 >= $DATETIME_MIN_TICKS and  value.to_i*1000 <= $DATETIME_MAX_TICKS
          setValue(idx, value.to_i*1000)
        else
          raise "DateTime out of range or value show be Integer and between -62135798400000 and 253402271999000."
        end
      elsif value.is_a?String
        begin
          tmpTime = Time.parse(value)
          setValue(idx, tmpTime.to_i*1000)
        rescue
          raise "Parse string to datetime failed, string:" + value
        end
      else
        raise "DateTime cell should be in Integer or Time or DateTime format, idx:" + idx.to_s + " value:" + value.to_s
      end
    end

    def setDecimal(idx, value)
      if value.is_a?String
        setValue(idx, value)
      elsif value.is_a?Float
          setValue(idx, value.to_s)
      elsif value.is_a?BigDecimal
        setValue(idx, value.to_s)
      else
        raise "value can not be convert to decimal, idx:" + idx.to_s + " value:" + value.to_s
      end
    end

    def setString(idx, value)
      if value.is_a?String and value.length < $STRING_MAX_LENTH
        setValue(idx, value)
      else
        raise "value show be String and len < " + $STRING_MAX_LENTH.to_s + ", idx:" + idx.to_s + " value:" + value.to_s
      end
    end

    private
    def setValue(idx, value)
      if idx < 0 or idx >= @mSchema.getColumnCount
        raise "idx out of range, idx:" + idx.to_s + " value:" + value.to_s
      end
      @mValues[idx] = value
    end
  end

  class OdpsTable
    def initialize(odpsConfig, projectName, tableName)
      @mOdpsConfig = odpsConfig
      @mProjectName = projectName
      @mTableName = tableName
    end

    #get partitions and return an array like :[{"time"=>"2016", "place"=>"china2"},{"time"=>"2015", "place"=>"china"}]
    def getPartitionList
      partitionList = Array.new
      url = "/projects/" + @mProjectName +"/tables/" +  @mTableName
      lastMarker = nil
      isEnd = false
      while !isEnd do
        header = Hash.new
        param = Hash.new
        param[$PARAM_CURR_PROJECT] = @mProjectName
        param[$PARAM_EXPECT_MARKER] = true
        param[$PARAM_PARTITIONS] = ""
        if lastMarker != nil
          param[$PARAM_MARKER] = lastMarker
        end
        conn = HttpConnection.new(@mOdpsConfig, header, param, url, "GET", "", true)
        res = conn.getResponse
        if res.code != "200"
          return partitionList
          #raise OdpsDatahubException.new($INVALID_ARGUMENT, "This not a partitioned table")
        end

        doc = REXML::Document.new(res.body.to_s)

        #parse partitions
        partitionsXml = doc.root.get_elements("Partition")
        partitionsXml.each { |partition|
          partitionInfo = Hash.new
          partition.elements.each { |column|
            partitionInfo[column.attributes["Name"]] = column.attributes["Value"]
          }
          partitionList.push(partitionInfo)
        }

        #get marker
        markerXml = doc.root.get_elements("Marker")
        if markerXml[0].text == nil
          isEnd = true
        elsif
          lastMarker = markerXml[0].text
        end
      end
      return partitionList
    end

    #ptStr ex: 'dt=20150805,hh=08,mm=24'
    #call add partiton if not exsits
    def addPartition(ptStr)
      pts_array = ptStr.split(',')
      sqlstr = "ALTER TABLE " + @mProjectName + "." + @mTableName
      sqlstr = sqlstr +  " ADD IF NOT EXISTS" + " PARTITION ("
      pts_array.each { |pt|
        ptkv = pt.split('=')
        if ptkv.size != 2
          raise "invalid partition spec" + pt
        end
        sqlstr += ptkv[0] + '=' + "'" + ptkv[1] + "'" + ','
      }
      sqlstr = sqlstr[0..-2] + ");"
      taskName = "SQLAddPartitionTask"
      runSQL(taskName, sqlstr)
    end

    def runSQL(taskName, sqlstring)
      task_xml = XmlTemplate.getTaskXml(taskName, sqlstring)

      job_xml = genJobXml('arbitriary_job', '9', "", task_xml)
      headers = Hash.new
      headers['Content-Type'] = 'application/xml'
      headers['Content-MD5'] = Digest::MD5.hexdigest(job_xml)
      headers['Content-Length'] = job_xml.size.to_s

      params = Hash.new

      url = "/projects/" + @mProjectName +"/instances"
      conn = HttpConnection.new(@mOdpsConfig, headers, params, url, 'POST', job_xml, true)

      res = conn.getResponse
      if res.code != '200'
        raise "Add partition failed with error" + res.code.to_s
      end

      if res.to_hash['Content-Length'] != "0" and not res.body.to_s.include?"Instance"
        raise res.body
      end

      waitForSQLComplete(res)
    end

    #TODO support mulit task
    def genJobXml(name, priority, comment, taskStr, runMode='sequence')
      job_xml = XmlTemplate.getJobXml(name, priority, comment, taskStr, runMode)
      return job_xml
    end

    def waitForSQLComplete(res)
      ret_headers = res.to_hash
      instanceurl =  "/projects/" + @mProjectName +"/instances" + "/" + ret_headers['location'][0].split('/')[-1]

      headers = Hash.new
      params = Hash.new
      params['taskstatus'] = ""
      res = nil

      while true
        conn = HttpConnection.new(@mOdpsConfig, headers, params, instanceurl, 'GET', "", true)
        res = conn.getResponse
        doc = REXML::Document.new(res.body.to_s)
        insStatus = doc.root.elements["Status"].text
        if insStatus == 'Terminated'
          break;
        elsif insStatus == 'Running' or insStatus == 'Suspended'
          sleep(5)
        end
      end

      doc.root.elements.each('Tasks/Task') { |e|
        status = e.elements['Status'].text
        name = e.elements['Name'].text
        if status.to_s != 'Success'
          raise getTaskResult(instanceurl, name.to_s)
        end
      }
    end

    def getTaskResult(instanceurl, name)
      headers = Hash.new
      params = Hash.new
      params['result'] = ""
      res = nil

      conn = HttpConnection.new(@mOdpsConfig, headers, params, instanceurl, 'GET', "", true)
      res = conn.getResponse
      doc = REXML::Document.new(res.body.to_s)
      doc.root.elements.each('Tasks/Task') { |e|
        taskname = e.elements['Name'].text
        if taskname == name.to_s
          return e.elements['Result'].cdatas().to_s
        end
      }
    end
  end
end