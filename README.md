# issue946

This repo for [issue946](https://github.com/cloudwu/skynet/issues/946)

## 复现方法

```bash
cd  .git 同级目录下

make update3rd

make macosx

 ./server/skynet/skynet ./config/area.cluster1.config
```

打开一个新的 shell 后输入

```bash
cd  .git 同级目录下

./server/skynet/skynet ./config/wsmain.config
```

然后使用客户端连接 skynet，使用 top 发现 skynet 的内存占用率缓慢增加，大概 1M/min。挂机一天仍未释法。

## 注

1. 猜测是调用 skynet 的语法错误
2. 增加的 C 库已经用 [valgrind](http://valgrind.org/) 检测，未发现内存泄露
3. 打开了注释的 `#define MEMORY_CHECK` ，也没有看出什么端倪
