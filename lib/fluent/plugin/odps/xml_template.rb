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

module OdpsDatahub
  class XmlTemplate
    def self.getTaskXml(taskName, sqlString)
      task_template=%{<SQL>
        <Name>#{taskName}</Name>
        <Comment/>
        <Config>
          <Property>
            <Name>settings</Name>
            <Value>{"odps.sql.udf.strict.mode": "true"}</Value>
          </Property>
        </Config>
        <Query><![CDATA[#{sqlString}]]></Query>
      </SQL>
      }
      return task_template
    end

    def self.getJobXml(name, comment, priority, taskStr, runMode)
      job_template=%{<?xml version="1.0" encoding="utf-8"?>
        <Instance>
        <Job>
          <Name>#{name}</Name>
          <Comment>#{comment}</Comment>
          <Priority>#{priority}</Priority>
          <Tasks>
             #{taskStr}
          </Tasks>
          <DAG>
            <RunMode>#{runMode}</RunMode>
          </DAG>
        </Job>
        </Instance>}
      return job_template
    end
  end
end