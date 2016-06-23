# Aliyun ODPS Plugin for Fluentd

## 开始使用
---

### 介绍

- 开放数据处理服务(Open Data Processing Service，简称ODPS)是阿里巴巴自主研发的海量数据处理平台。主要服务于批量结构化数据的存储和计算，可以提供海量数据仓库的解决方案以及针对大数据的分析建模服务。
- ODPS DataHub Service(DHS)是一个ODPS的内建服务，向用户提供实时数据的发布(Publish)和订阅(Subscribe)的功能。发布的数据会自动被写入ODPS表中。所以DHS也可以做为ODPS导入数据的一个入口。
- 本插件提供向odps表通过DataHub服务写入数据的能力，并具备按用户要求的格式自动创建分区的功能。


### 环境要求

使用此插件，需要具备如下环境:

1. Ruby 2.1.0 或更新
2. Gem 2.4.5 或更新
3. Fluentd-0.10.49 或更新 (*[Home Page](http://www.fluentd.org/)*)
4. Protobuf-3.5.1 或更新(Ruby protobuf)
5. Ruby-devel

### 安装部署
安装部署Fluentd可以选择以下两种方式之一。
1. 一键安装包适用于第一次安装Ruby&Fluentd环境的用户或局域网用户，一键安装包包含了所需的Ruby环境以及Fluentd。目前一键安装包仅支持Linux环境。
2. 通过网络安装适用于对Ruby有了解的用户，需要提前确认Ruby版本，若低于2.1.0则需要升级或安装更高级的Ruby环境，然后通过RubyGem安装Fluentd。

注：
* RubyGem源建议更改为https://ruby.taobao.org/
* 局域网环境安装可以通过本地安装Gem文件
```
gem install --local fluent-plugin-aliyun-odps-0.1.2.gem
```

#### 安装方式一：一键安装包安装
1. 下载解压 [fluentd_package.tar.gz](http://gitlab.alibaba-inc.com/aliopensource/aliyun-odps-fluentd-plugin/blob/master/package/fluentd_package.tar.gz)
2. 可以修改install_agent.sh中$DIR为你想安装ruby的路径，默认会安装在当前路径下面
3. 执行如下命令，提示“Success”表示安装成功
```
bash install_agent.sh
```
4. fluentd程序会被安装在当前目录的bin目录下面

#### 安装方式二：通过网络安装
1. Ruby安装（已经存在Ruby 2.1.0以上环境可忽略此步骤）：
```
wget https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.0.tar.gz
tar xzvf ruby-2.3.0.tar.gz
cd ruby-2.3.0
./configure --prefix=DIR
make
make install
```
2 Fluentd以及插件安装
```
$ gem install fluent-plugin-aliyun-odps
```

### 插件使用示例
#### 示例一 上传csv文件中的数据
1. 首先需要在odps准备一张表，在这里假设表名为 students, 包含三个字段 id， name， score， 类型分别为string， string, bigint
2. 准备csv数据文件， 假设数据文件内容如下
```
1, jack ma, 90
2, pony zhang, 85
3, lucy wang, 88
```
3. 准备fluentd配置文件, 保存以下内容为文件fluentd.conf。
```
<source>
   type tail
   path /path/to/students.csv
   tag input.csv
   format csv
</source>
<match input.*>
  type aliyun_odps
  aliyun_access_id ************
  aliyun_access_key *********
  aliyun_odps_endpoint http://service.odps.aliyun.com/api
  aliyun_odps_hub_endpoint http://dh.odps.aliyun.com
  buffer_chunk_limit 2m
  buffer_queue_limit 128
  flush_interval 5s
  project your_projectName  #填写需要导入数据的project名称
  enable_fast_crc true
  <table input.csv>
	table students
	fields id,name,score
	shard_number 1
	retry_time 3
	retry_interval 1
	abandon_mode true
  </table>
</match>
```
4. 执行fluentd命令,并用-c指定配置文件
```
fluentd -c fluentd.conf
```
5. 完成后可用如下sql命令查询数据
```
select * from students;
```

#### 示例二 抓取上传实时nginx日志文件
1. 对于nginx日志文件，fluentd可用采用正则表达式的方式来解析数据。
2. 参考使用如下配置文件，执行命令同示例一。
```
<source>
   type tail
   path /home/admin/nginx/logs/access.log   #nginx log 地址
   pos_file /tmp/nginx.access.pos
   refresh_interval 5s
   tag nginx.access
   format /^(?<remote>[^ ]*) - \[(?<dt>[^\]]*)\] "(?<method>\S+) ((?<path>[^\"]*) +\S*)?" (?<code>[^ ]*) (?<size>[^ ]*) "(?<agent>[^\"]*)" "(?<requesttime>[^\"]*)"? $/  #解析日志的正则表达式
   time_format %d/%b/%Y:%H:%M:%S %z
</source>
<match nginx.access>
  type aliyun_odps
  aliyun_access_id ************
  aliyun_access_key *********
  aliyun_odps_endpoint http://service.odps.aliyun.com/api
  aliyun_odps_hub_endpoint http://dh.odps.aliyun.com
  buffer_chunk_limit 2m
  buffer_queue_limit 128
  flush_interval 5s
  project your_projectName
  enable_fast_crc true
  data_encoding UTF-8
  <table nginx.access>
  table nginx_logs #对应日志写入的odps表
  fields remote,method,path,code,size,agent,requesttime
  shard_number 5
	partition ctime=${datetime.strftime('%Y%m%d')}
	time_format %d/%b/%Y:%H:%M:%S %z
	shard_number 1
	retry_time 3
	retry_interval 1
	abandon_mode true
  </table>
</match>
```

#### 示例三导入MySQL中的数据
1. mysql

### 参数说明

- type(Fixed): 固定值 aliyun_odps.
- aliyun_access_id(Required):阿里云access_id.
- aliyun_access_key(Required):阿里云access key.
- aliyun_odps_hub_endpoint(Required):如果你的服务部署在ECS上，请把本值设定为 http://dh-ext.odps.aliyun-inc.com, 否则设置为 http://dh.odps.aliyun.com.
- aliyunodps_endpoint(Required):如果你的服务部署在ECS上，请把本值设定为 http://odps-ext.aiyun-inc.com/api, 否则设置为 http://service.odps.aliyun.com/api .
- buffer_chunk_limit(Optional): 块大小，支持“k”(KB),“m”(MB)单位，默认 8MB，建议值2MB, 目前最大支持20MB.
- buffer_queue_limit(Optional): 块队列大小，此值与buffer_chunk_limit共同决定整个缓冲区大小。
- flush_interval(Optional): 强制发送间隔，达到时间后块数据未满则强制发送, 默认 60s.
- abandon_mode(Optional):内置重试三次后抛弃该pack数据。
- project(Required): project名称.
- table(Required): table名称.
- fields(Required): 与source对应，字段名必须存在于source之中.
- partition(Optional)：若为分区表，则设置此项.
    - 分区名支持的设置模式:
        - 固定值: partition ctime=20150804
        - 关键字: partition ctime=${remote} （其中remote为source中某字段）
        - 时间格式关键字: partition ctime=${datetime.strftime('%Y%m%d')} （其中datetime为source中某时间格式字段，输出为%Y%m%d格式作为分区名称）
- time_format(Optional):
    - 如果使用时间格式关键字为<partition>, 请设置本参数. 例如: source[datetime]="29/Aug/2015:11:10:16 +0800",则设置<time_format>为"%d/%b/%Y:%H:%M:%S %z"
- shard_number(Optional):指定shard数量，将会随机向shard[0,shard_number-1]范围内的shard中写入数据，必须为大于0且小于table对应shard数量上限的整数.
- enable_fast_crc(Optional): 使用快速crc计算，这将极大提升性能，但是由于使用了外部加载的动态链接库，目前仅支持64位linux、windows系统.
- retry_time(Optional): 发送每个pack数据时内置重试次数，默认3次.
- retry_interval(Optional): 重试间隔，默认1s.
- abandon_mode(Optional): 默认为false，设置成true会在重试retry_time后抛弃该数据包，否则会将异常抛送给fluentd，利用fluentd的重试机制重试，这种情况可能会导致数据重复.
- data_encoding(Optional): 默认使用源数据标示的encode方式，根据string.encoding获取，如果需要指定源数据编码方式，请设置该值，支持的类型："US-ASCII", "ASCII-8BIT", "UTF-8", "ISO-8859-1", "Shift_JIS", "EUC-JP", "Windows-31J", "BINARY", "CP932", "eucJP"

## 常见使用问题以及异常描述
---
* 程序抛出异常InvalidShardId/ShardNotReady是什么原因导致？
 - 可能系统正在升级，会短暂出现这个问题，会在短时间内恢复；
 - fluentd如果存在多个进程请查看配置项shard_num是否都配置成了一样的值（或都不配置），如果配置不一样是会导致这个问题的，shard_number少的进程会把多余shard Unload掉；
 - 可能存在另外的使用sdk等方式进行了loadshard/unloadshard等操作。
* enable_fast_crc如何检查是否兼容？
 - 开启此配置后再启动fluentd进程，启动时会验证，如果失败会抛出错误原因（reload不会进行验证），或进入插件目录后利用ldd查看aliyun-odps-fluentd-plugin/lib/fluent/plugin/crc/lib/linux/crc32c.so。
* retry_time/retry_interval与fluentd自带的retry有何区别？
 - fluentd自带retry默认持续36小时，会将整个buffer_chunk重发，配置动态partition情况下重发全部数据可能造成数据重复。配置这两项就会使用插件内部重试，如果重试失败，会再根据abandon_mode的值判定放弃该pack的数据还是交给fluentd重发整个buffer。
* Warning：ErrorCode: NoSuchPartition, Message: write failed because The specified partition does not exist.是什么意思？
 - 本插件会再catch到Odps的NoSuchPartition时会主动创建分区，如果遇到这个warn表示Odps表中不存在数据对应分区，会自动创建，如果创建成功会有信息提示。
* Fluent::BufferQueueLimitError error="queue size exceeds limit"是什么原因？
 - fluentd在读取数据-发送数据过程中，会先读取到一个buffer中，具体大小根据配置中buffer_chunk_limit与buffer_queue_limit共同决定，如果遇到这个错误，很可能是因为堆积数据导致buffer不足，可以尝试增大buffer_queue_limit解决这个问题。
* 多个config文件如何分别启动一个fluentd进程？
 - 如果存在多个config文件，可以使用in_multiprocess这个插件同时启动不同的进程来服务。
* partition has no corresponding source key or the partition expression is wrong.这个异常是什么原因？
 - 这个异常表示在source data中找不到配置在partition字段中的值，例如partition ctime=${remote}，而remote没有出现在source中，请检查配置。
* Failed to format the data.这个异常是什么原因？
 - 这个错误信息抛出代表解析partition过程出现问题，请检查partition配置，如果数据中存在脏数据也可能遇到这个问题。
* 如何更改为淘宝源RubyGem？
 - RubyGems 镜像[https://ruby.taobao.org/]
* 导入数据抛异常"\xE8" from ASCII-8BIT to UTF-8 (Encoding::UndefinedConversionError)
 - 该错误往往由于source插件在读取数据时，数据真实编码为utf-8,但是transport给fluend的string.encoding却为ASCII-8BIT导致类似错误，这种情况需要设置data_encoding来进行转码。
 
 ## 官方网站
 - [Fluentd User Guide](http://docs.fluentd.org/)

 ## 作者
 - [Sun Zongtao]()
 - [Cai Ying]()
 - [Dong Xiao](https://github.com/dongxiao1198)
 - [Yang Hongbo](https://github.com/hongbosoftware)

 ## License
 licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0.html)
