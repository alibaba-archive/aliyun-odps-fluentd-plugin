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
require 'base64'
require 'openssl'
require_relative '../exceptions'
require_relative '../conf/config'
require_relative 'http_flag'
Net::HTTP.version_1_2

module OdpsDatahub
  class HttpConnection
    attr_reader :mHeader, :mParam, :mUri, :mReq, :mMethod, :mPath, :mStream, :mOdpsConfig
    def initialize(odpsConfig, headers, params, path, method, stream = nil, isodpsurl = false)
      @mOdpsConfig = odpsConfig
      @mHeader = headers
      @mParam = params
      @mPath = path
      @mMethod = method
      @mStream = stream
      @mIsOdpsUrl = isodpsurl
      buildRequest
    end

    def buildRequest
      path = ""
      separater = '?'
      @mParam.each { |key , value|
        if value != ""
          path += separater + key.to_s + '=' + value.to_s
        else
          path += separater + key.to_s
        end
        separater = '&'
      }
      if @mIsOdpsUrl
        @mUri = URI.parse(@mOdpsConfig.odpsEndpoint + @mPath + path)
      else
        @mUri = URI.parse(@mOdpsConfig.datahubEndpoint + @mPath + path)
      end

      if !@mHeader.has_key?($CONTENT_MD5)
        @mHeader[$CONTENT_MD5] = ""
      end
      if !@mHeader.has_key?($CONTENT_TYPE)
        @mHeader[$CONTENT_TYPE] = ""
      end
      @mHeader[$DATE] = Time.now.utc.strftime("%a, %d %b %Y %H:%M:%S GMT")
      if not @mIsOdpsUrl
        @mHeader[$TUNNEL_STREAM_VERSION] = "1"
        @mHeader[$TUNNEL_VERSION] = "3"
      end
      @mHeader[$USER_AGENT] = $SDK_UA_STR + @mOdpsConfig.userAgent
      @mHeader[$AUTHORIZATION] = signAuthorization
      case @mMethod
        when "POST"
          @mReq = ::Net::HTTP::Post.new(mUri.to_s, @mHeader)
          @mReq.body = @mStream
        when "GET"
          @mReq = ::Net::HTTP::Get.new(mUri.to_s, @mHeader)
        when "PUT"
          @mReq = ::Net::HTTP::Put.new(mUri.to_s, @mHeader)
          @mReq.body = @mStream
        else
          raise OdpsDatahubException.new($INVALID_ARGUMENT, "invalid method")
      end
    end

    def getResponse()
      res = Net::HTTP.start(@mUri.host, @mUri.port) {|http|
        http.request(@mReq)
      }
      return res
    end

    def signAuthorization
      prefix = "x-odps-"
      stringToSign = @mMethod + "\n"
      accessKey = @mOdpsConfig.accessKey
      headerMapDown = Hash.new

      @mHeader.each { |key , value|
        keyDown = key.downcase
        headerMapDown[keyDown] = value
      }
      headerArray = headerMapDown.sort

      headerArray.each { |key , value|
        if key.start_with?(prefix)
          stringToSign << key << ":" << value
          stringToSign << "\n"
        elsif key == 'content-type' or key == 'content-md5' or key == 'date'
          stringToSign << value
          stringToSign << "\n"
        end
      }

      signParam = ""
      separater = '?'
      paramArray = @mParam.sort
      paramArray.each { |key , value|
        if value != ""
          signParam += separater + key.to_s + '=' + value.to_s
        else
          signParam += separater + key.to_s
        end
        separater = '&'
      }
      stringToSign += @mPath + signParam
      #puts stringToSign
      signedStr =  "ODPS " + @mOdpsConfig.accessId + ":" + Base64.encode64("#{OpenSSL::HMAC.digest('sha1', accessKey, stringToSign)}").to_s
    end
  end
end
