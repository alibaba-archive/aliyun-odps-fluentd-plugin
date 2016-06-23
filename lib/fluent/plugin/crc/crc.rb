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
require 'rbconfig'
module OdpsDatahub
  class CrcCalculator
    # @param [StringIO] data
    # @return crc32c to_i
    def self.calculate(data)
      if (!$USE_FAST_CRC)
        require_relative 'origin/crc32c'
        crc32c = Digest::CRC32c.new
        crc32c.update(data.string)
        return crc32c.checksum.to_i
      elsif getOsType == "linux" || getOsType == "unix"
        require_relative 'lib/linux/crc32c.so'
        return Crc32c.calculate(data.string, data.length, 0).to_i
      elsif getOsType == "windows"
        require_relative 'lib/win/crc32c.so'
        return Crc32c.calculate(data.string, data.length, 0).to_i
      end
    end

    def self.getOsType
      host_os = RbConfig::CONFIG['host_os']
      case host_os
        when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
          "windows"
        when /linux/
          "linux"
        when /solaris|bsd/
          "unix"
        else
          raise "unspport os"
      end
    end
  end
end