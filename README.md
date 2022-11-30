# 简介

- RR调度的操作系统内核
- 用于学习操作系统

# 开发环境

- Ubuntu-20.24.LTS

# 开发工具

|     工具    |    版本   |
|-------------|----------|
| bochs       |  2.6.11  |
| bximage     |  2.6.11  |
| dd          |  8.30    |
| objcopy     |  2.34    |
| ld          |  2.34    |
| gcc         |  9.4.0   |
| nasm        |  2.14.02 |
| cmake       |  3.16    |

# 编译和使用
- 由于cmake编译指令过长，在顶层使用make进行配置，编译。
- 编译完成后会在当前目录下生成bochsrc，直接在命令行输入bochs进行启动。