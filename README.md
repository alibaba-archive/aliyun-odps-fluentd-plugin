# Aliyun ODPS Plugin for Fluentd

## Getting Started
---

### Introduction

- ODPS-Open Data Processing Service is a massive data processing platform designed by alibaba.
- DHS-ODPS DataHub Service is a service in Odps, which provides real-time upload and download functions for user.

### Requirements

To get started using this plugin, you will need these things:

1. Ruby 2.1.0 or later
2. Gem 2.4.5 or later
3. Fluentd-0.10.49 or later (*[Home Page](http://www.fluentd.org/)*)
4. Protobuf-3.5.1 or later(Ruby protobuf)

### Install the Plugin

install the project from gem or github:

```
$ gem install fluent-plugin-aliyun-odps
$ git clone https://github.com/aliyun/aliyun-odps-fluentd-plugin.git
```

Use gem to install dependency:

```
$ gem install protobuf
$ gem install fluentd --no-ri --no-rdoc
```

Your plugin is in aliyun-odps-fluentd-plugin/lib/fluent/plugin, entry file is out_odps.rb.

### Use the Plugin

- If you installed this plugin from gem, please ignore this step.
- Move the plugin dir into the plugin directory of Fluentd.
- (i.e., copy the folder aliyun-odps-fluentd-plugin/lib/fluent/plugin into {YOUR_FLUENTD_DIRECTORY}/lib/fluent/plugin).

```
$ cp aliyun-odps-fluentd-plugin/lib/fluent/plugin/* {YOUR_FLUENTD_DIRECTORY}/lib/fluent/plugin/ -r
```

### ODPS Fluentd plugin now is available. Following is a simple example of how to write ODPS output configuration.

```
<source>
   type tail
   path /opt/log/in/in.log
   pos_file /opt/log/in/in.log.pos
   refresh_interval 5s
   tag in.log
   format /^(?<remote>[^ ]*) - - \[(?<datetime>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*?)(?: +\S*)?)?" (?<code>[^ ]*) (?<size>[^ ]*) "-" "(?<agent>[^\"]*)"$/
   time_format %Y%b%d %H:%M:%S %z
</source>
```
```
<match in.**>
  type aliyun_odps
  aliyun_access_id ************
  aliyun_access_key *********
  aliyun_odps_endpoint http://service.odps.aliyun.com/api
  aliyun_odps_hub_endpoint http://dh.odps.aliyun.com
  buffer_chunk_limit 2m
  buffer_queue_limit 128
  flush_interval 5s
  project your_projectName
  <table in.log>
	table your_tableName
	fields remote,method,path,code,size,agent
	partition ctime=${datetime.strftime('%Y%m%d')}
	time_format %d/%b/%Y:%H:%M:%S %z
	shard_number 1
  </table>
</match>
```
### Parameters
- type(Fixed): always be aliyun_odps.
- aliyun_access_id(Required):your aliyun access id.
- aliyun_access_key(Required):your aliyun access key.
- aliyun_odps_hub_endpoint(Required):if you are using ECS, set it as http://dh-ext.odps.aliyun-inc.com, otherwise using http://dh.odps.aliyun.com.
- aliyunodps_endpoint(Required):if you are using ECS, set it as http://odps-ext.aiyun-inc.com/api, otherwise using http://service.odps.aliyun.com/api .
- buffer_chunk_limit(Optional):chunk size,¡°k¡± (KB), ¡°m¡± (MB), and ¡°g¡± (GB) £¬default 8MB£¬recommended number is 2MB.
- buffer_queue_limit(Optional):buffer chunk size£¬example: buffer_chunk_limit2m£¬buffer_queue_limit 128£¬then the total buffer size is 2*128MB.
- flush_interval(Optional):interval to flush data buffer, default 60s.
- project(Required):your project name.
- table(Required):your table name.
- fields(Required): must match the keys in source.
- partition(Optional)£ºset this if your table is partitioned.
    - partition format:
        - fix string: partition ctime=20150804
        - key words: partition ctime=${remote}
        - key words int time format: partition ctime=${datetime.strftime('%Y%m%d')}
- time_format(Optional):
    - if you are using the key words to set your <partition> and the key word is in time format, please set the param <time_format>. example: source[datetime] = "29/Aug/2015:11:10:16 +0800", and the param <time_format> is "%d/%b/%Y:%H:%M:%S %z"
- shard_number(Optional):less than the number you set when create the hubtable.

## Useful Links
---

- [Fluentd User Guide](http://docs.fluentd.org/)

## Authors && Contributors
---

- [Sun Zongtao]()
- [Cai Ying]()
- [Dong Xiao](https://github.com/dongxiao1198)
- [Yang Hongbo](https://github.com/hongbosoftware)

## License
---

licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0.html)
