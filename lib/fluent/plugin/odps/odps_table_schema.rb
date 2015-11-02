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
  $ODPS_BIGINT = "bigint"	      #8字节有符号整型
  $ODPS_DOUBLE = "double"	      #8字节双精度浮点型
  $ODPS_BOOLEAN = "boolean"     #布尔型
  $ODPS_DATETIME = "datetime"	  #日期类型，取值范围是0001-01-01 00:00:00 ~ 9999-12-31 23:59:59
  $ODPS_STRING = "string"	    #字符串类型
  $ODPS_DECIMAL = "decimal"	    #字符串类型

  class OdpsTableColumn
    attr_reader :mName, :mType, :mIdx
    def initialize(name, type, idx)
      @mName = name
      @mType = type
      @mIdx = idx
    end
  end

  class OdpsTableSchema
    attr_accessor :mCols
    def initialize(jsonobj = nil)
      @mCols = Array.new
      if jsonobj != nil
        columns = jsonobj["columns"]
        columns.each do |object|
          appendColumn(object["name"], object["type"])
        end
      end
    end

    def getColumnCount
      @mCols.size
    end

    def getColumnType(idx)
      if idx < 0 or idx >= @mCols.size
        raise "idx out of range"
      end
      @mCols.at(idx).mType
    end

    def appendColumn(name, type)
      col = OdpsTableColumn.new(name, type, @mCols.size)
      @mCols.push(col)
    end
  end
end

