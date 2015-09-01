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
require 'stringio'
require 'protobuf'
require_relative '../exceptions'
require_relative '../digest/crc32c'
require_relative '../odps/odps_table'

module OdpsDatahub

  $TUNNEL_META_COUNT = 33554430 #  magic num 2^25-2
  $TUNNEL_META_CHECKSUM = 33554431 #  magic num 2^25-1
  $TUNNEL_END_RECORD = 33553408 #  maigc num 2^25-1024

  class Serializer
    def encodeBool(value)
      [value ? 1 : 0].pack('C')
    end

    def encodeDouble(value)
      [value].pack('E')
    end

    def encodeSInt64(value)
      if value >= 0
        ::Protobuf::Field::VarintField.encode(value << 1)
      else
        ::Protobuf::Field::VarintField.encode(~(value << 1))
      end
    end

    def encodeUInt32(value)
      return [value].pack('C') if value < 128
      bytes = []
      until value == 0
        bytes << (0x80 | (value & 0x7f))
        value >>= 7
      end
      bytes[-1] &= 0x7f
      bytes.pack('C*')
    end

    def encodeDataTime(value)
      self.encodeSInt64(value)
    end

    def encodeString(value)
      value_to_encode = value.dup
      value_to_encode.encode!(::Protobuf::Field::StringField::ENCODING, :invalid => :replace, :undef => :replace, :replace => "")
      value_to_encode.force_encoding(::Protobuf::Field::BytesField::BYTES_ENCODING)
      string_bytes = ::Protobuf::Field::VarintField.encode(value_to_encode.size)
      string_bytes << value_to_encode
    end

    def encodeFixed64(value)
      # we don't use 'Q' for pack/unpack. 'Q' is machine-dependent.
      [value & 0xffff_ffff, value >> 32].pack('VV')
    end

    def encodeFixed32(value)
      [value].pack('V')
    end

    def encodeFixedString(value)
      [value].pack('V')
    end

    def writeTag(idx, type, stream)
      key = (idx << 3) | type
      stream << ::Protobuf::Field::VarintField.encode(key)
    end

    def serialize(upStream, recordList)
      crc32cPack = ::Digest::CRC32c.new
      if recordList.is_a?Array
        recordList.each { |record|
          crc32cRecord = ::Digest::CRC32c.new
          schema = OdpsTableSchema.new
          schema = record.getTableSchema
          schema.mCols.each { | col |
            cellValue = record.getValue(col.mIdx)
            if cellValue == nil
              next
            end
            crc32cRecord.update(encodeFixed32(col.mIdx + 1))
            case col.mType
              when $ODPS_BIGINT
                crc32cRecord.update(encodeFixed64(cellValue))
                writeTag(col.mIdx + 1, ::Protobuf::WireType::VARINT, upStream)
                upStream.write(encodeSInt64(cellValue))
              when $ODPS_DOUBLE
                crc32cRecord.update(encodeDouble(cellValue))
                writeTag(col.mIdx + 1, ::Protobuf::WireType::FIXED64, upStream)
                upStream.write(encodeDouble(cellValue))
              when $ODPS_BOOLEAN
                crc32cRecord.update(encodeBool(cellValue))
                writeTag(col.mIdx + 1, ::Protobuf::WireType::VARINT, upStream)
                upStream.write(encodeBool(cellValue))
              when $ODPS_DATETIME
                crc32cRecord.update(encodeFixed64(cellValue))
                writeTag(col.mIdx + 1, ::Protobuf::WireType::VARINT, upStream)
                upStream.write(encodeDataTime(cellValue))
              when $ODPS_STRING
                crc32cRecord.update(cellValue)
                writeTag(col.mIdx + 1, ::Protobuf::WireType::LENGTH_DELIMITED, upStream)
                upStream.write(encodeString(cellValue))
              else
                raise OdpsDatahubException.new($INVALID_ARGUMENT, "invalid mType")
            end
          }
          recordCrc = crc32cRecord.checksum.to_i
          writeTag($TUNNEL_END_RECORD, ::Protobuf::WireType::VARINT, upStream)
          upStream.write(encodeUInt32(recordCrc))
          crc32cPack.update(encodeFixed32(recordCrc))
        }
        writeTag($TUNNEL_META_COUNT, ::Protobuf::WireType::VARINT, upStream)
        upStream.write(encodeSInt64(recordList.size))
        writeTag($TUNNEL_META_CHECKSUM, ::Protobuf::WireType::VARINT, upStream)
        upStream.write(encodeUInt32(crc32cPack.checksum))
      else
        raise OdpsDatahubException.new($INVALID_ARGUMENT, "param must be a array")
      end
    end
  end
end
