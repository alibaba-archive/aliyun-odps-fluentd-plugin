<<<<<<< HEAD
# Aliyun ODPS Plugin for Fluentd

## Getting Started
---

### Requirements

To get started using this plugin, you will need three things:

1. Ruby 2.1.0 or later
2. Gem 2.4.5 or later
3. Fluentd-0.10.49 or later (*[Home Page](http://www.fluentd.org/)*)
4. Protobuf-3.5.1 or later(Ruby protobuf)

### Clone the Code

Clone the project from gitlab:

```
$ git clone git@gitlab.alibaba-inc.com:aliopensource/aliyun-odps-fluentd-plugin.git
```

Use gem to install dependency:

```
$ gem install protobuf
$ gem install fluentd --no-ri --no-rdoc
```

Your plugin is in aliyun-odps-fluentd-plugin/lib/fluent/plugin, entry file is out_odps.rb.

### Use the Plugin

Move the plugin dir into the plugin directory of Fluentd.
(i.e., copy the folder aliyun-odps-fluentd-plugin/lib/fluent/plugin into {YOUR_FLUENTD_DIRECTORY}/lib/fluent/plugin).

```
$ cp aliyun-odps-fluentd-plugin/lib/fluent/plugin/* {YOUR_FLUENTD_DIRECTORY}/lib/fluent/plugin/ -r
```

### ODPS Fluentd plugin now is available. Following is a simple example of how to write ODPS output configuration.

```
<source>
   type tail
   path /opt/log/in/in.log
   refresh_interval 5s
   tag in.log
   format csv
   keys dt,week,r1,r2,r3,r4,r5,r6,r7,blue
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
	fields r1,r2,r3,r4,r5,r6,blue
	partition ctime=${dt.strftime('%Y%m%d')}
	time_format %d/%b/%Y:%H:%M:%S %z
	shard_number 1
  </table>
</match>
```
  1.The fields in match will match the key in source.\<br>
  2.partition format:
    1)fix string: partition ctime=20150804\<br>
    2)key words: partition ctime=${dt.strftime('%Y%m%d')}\<br>
  3.partition or time_format is optional:\<br>
    1)if the odps table is partitioned, you need to set the param <partition>\<br>
    2)if you are using the key words to set your <partition> and the key word is in time format,\<br>
    please set the param <time_format>\<br>
    example: source[dt] = "29/Aug/2015:11:10:16 +0800", and the param <time_format> is "%d/%b/%Y:%H:%M:%S %z"\<br>
  4.shard_number:less than the number you set when create the hubtable.\<br>
  5.buffer_chunk_limit:chunk size,¡°k¡± (KB), ¡°m¡± (MB), and ¡°g¡± (GB) £¬default 8MB£¬recommended number is 2MB.\<br>
  6.buffer_queue_limit:buffer chunk size£¬example: buffer_chunk_limit2m£¬buffer_queue_limit 128£¬then the total buffer size is 2*128MB.\<br>


## Useful Links
---

- [Fluentd User Guide](http://docs.fluentd.org/)

## Authors && Contributors
---

- [Sun Zongtao]()
- [Cai Ying]()
- [Dong Xiao]()
- [Yang Hongbo](https://github.com/hongbosoftware)

## License
---

licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0.html)
=======
# aliyun-odps-fluentd-plugin
>>>>>>> 5972a47ee92cdb7c480b6be917364089a83c257d
