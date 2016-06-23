0.0.4
Fix datetime format bug, support String, DateTime, Time type when write to a datetime field.
0.0.5
Add reload shard when import fails, and remove unload shard operation when shut down.
0.0.6
Add decimal support，fix string input while setting double and int.
0.0.7
Add error msg when add partition fail, support fast crc， remove pack size limit.
0.0.8
Add abandon mode, fix fluent retry bug, fix partition mixed mode bug.
0.0.9
Hotfix retry log error bug.
0.1.0
Add partition when catch NoSuchPartition.
0.1.1
Fix some log format.
0.1.2
Use XStreamPack.
0.1.3
Drop record with error log when parse partition failed.
0.1.5
Fix string encode replace unknow char
0.1.6
Fix raise exception bug
0.1.7
Add data_encoding config to format data.