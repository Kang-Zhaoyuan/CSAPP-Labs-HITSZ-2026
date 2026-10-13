# 计算机体系结构实验 Agent 规范与环境备忘

## 1. 网络环境与私网路由限制

- 实验平台物理 IP 映射：
  - 指导书平台 `arch.p.cs-lab.top`：私网 IP `10.249.12.224`
  - 评测平台 `grader.hitsz.edu.cn`：私网 IP `10.249.12.224`
  - 文件下载站：`http://10.249.14.10:3011/`
- 代理冲突（WinError 10054 / Connection Reset）：
  本地若开启代理（Clash / VPN / TUN），外部节点无法路由校园私网 IP。命令行请求须显式指定直连映射：
  ```bash
  curl.exe --connect-to arch.p.cs-lab.top:443:10.249.12.224:443 https://arch.p.cs-lab.top/...
  curl.exe --connect-to grader.hitsz.edu.cn:443:10.249.12.224:443 https://grader.hitsz.edu.cn/...
  ```
  代理配置须确保 `10.0.0.0/8` 及对应域名走 DIRECT 规则。

## 2. 容器环境隔离与端口冲突防范

- 宿主机多容器共存：
  - 操作系统实验容器：`qemu-ubuntu`，宿主机端口 `2222`，SSH 别名 `os-lab-docker`
  - 体系结构实验容器：`csapp-env`，宿主机端口 `2224`，SSH 别名 `csapp-docker`
- 破坏性命令限制：严禁在宿主机执行 `docker stop $(docker ps -aq)` 或 `docker rm -f $(docker ps -aq)` 等全局操作，以免中断其他实验容器。
- 目录映射：宿主机 `D:\HIT\CSAPP` 挂载至容器内部 `/workspace`。

## 3. 硬件计数器要求

- perf 性能计数器与 Cache 数据采集在虚拟机或 WSL 下失真，评测数据需在独立 Linux 环境或支持 PMU 的容器下运行。

## 4. 指导书同步机制

- 运行 `python docs/sync_docs.py` 会请求 `arch.p.cs-lab.top/search/search_index.json`，动态更新 `docs/` 下的章节指导书与素材。
