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
require 'digest'
module Digest
  #
  # Base class for all CRC algorithms.
  #
  class CRC < Digest::Class
    include Digest::Instance
    # The initial value of the CRC checksum
    INIT_CRC = 0x00
    # The XOR mask to apply to the resulting CRC checksum
    XOR_MASK = 0x00
    # The bit width of the CRC checksum
    WIDTH = 0
    #
    # Calculates the CRC checksum.
    #
    # @param [String] data
    #   The given data.
    #
    # @return [Integer]
    #   The CRC checksum.
    #
    def self.checksum(data)
      crc = self.new
      crc << data
      return crc.checksum
    end
    #
    # Packs the given CRC checksum.
    #
    # @return [String]
    #   The packed CRC checksum.
    #
    def self.pack(crc)
      ''
    end
    #
    # Initializes the CRC checksum.
    #
    def initialize
      @crc = self.class.const_get(:INIT_CRC)
    end
    #
    # The input block length.
    #
    # @return [1]
    #
    def block_length
      1
    end
    #
    # The length of the digest.
    #
    # @return [Integer]
    #   The length in bytes.
    #
    def digest_length
      (self.class.const_get(:WIDTH) / 8.0).ceil
    end
    #
    # Updates the CRC checksum with the given data.
    #
    # @param [String] data
    #   The data to update the CRC checksum with.
    #
    def update(data)
    end
    #
    # @see {#update}
    #
    def <<(data)
      update(data)
      return self
    end
    #
    # Resets the CRC checksum.
    #
    # @return [Integer]
    #   The default value of the CRC checksum.
    #
    def reset
      @crc = self.class.const_get(:INIT_CRC)
    end
    #
    # The resulting CRC checksum.
    #
    # @return [Integer]
    #   The resulting CRC checksum.
    #
    def checksum
      @crc ^ self.class.const_get(:XOR_MASK)
    end
    #
    # Finishes the CRC checksum calculation.
    #
    # @see {pack}
    #
    def finish
      self.class.pack(checksum)
    end
  end
end