# 计算机体系结构实验（CSAPP / Architecture Lab）Agent 备忘与开发规范

本文档为后续接手的 Agent 提供项目上下文、网络环境配置规范以及实验资源索引。

---

## 🌐 1. 校园网与代理环境避坑指南（重要）

### 1.1 关键内网服务与 IP 映射
哈工大（深圳）的实验与评测服务部署在**校园局域网私有 IP**（`10.x.x.x`）上：
- **实验指导书平台**：`https://arch.p.cs-lab.top/`
  - 真实 IP：`10.249.12.224`（CNAME 指向 `dell1.metal.osa.moe`）
- **作业在线评测平台**：`https://grader.hitsz.edu.cn/`
  - 真实 IP：`10.249.12.224`
- **校园网文件下载站**：`http://10.249.14.10:3011/`
  - 用于下载 `lab1.tar.gz`、`lab2.tar.gz` 等实验源码包。

### 1.2 代理（Clash / TUN）冲突说明与解决方案
当本地环境开启 Clash / VPN 时，若请求被转发至外部代理节点，外部节点无法连通校园私有 IP，将导致 `WinError 10054` 或连接被强行重置（Connection Reset）。

**解决方案**：
1. **网络请求命令指定直连映射**：
   在编写脚本或命令行下载时，优先使用直接 IP 映射：
   ```bash
   curl.exe --connect-to arch.p.cs-lab.top:443:10.249.12.224:443 https://arch.p.cs-lab.top/...
   curl.exe --connect-to grader.hitsz.edu.cn:443:10.249.12.224:443 https://grader.hitsz.edu.cn/...
   ```
2. **Clash 配置文件规则**：
   已在 `Clash.for.Windows-0.20.16-ikuuu\data\profiles\` 的各 Profile 文件中注入了以下配置：
   ```yaml
   hosts:
     arch.p.cs-lab.top: 10.249.12.224
     grader.hitsz.edu.cn: 10.249.12.224
     dell1.metal.osa.moe: 10.249.12.224

   rules:
     - DOMAIN-SUFFIX,cs-lab.top,DIRECT
     - DOMAIN-SUFFIX,hitsz.edu.cn,DIRECT
     - DOMAIN-SUFFIX,hit.edu.cn,DIRECT
     - DOMAIN-SUFFIX,osa.moe,DIRECT
     - IP-CIDR,10.0.0.0/8,DIRECT,no-resolve
   ```

---

## 📚 2. 本地离线实验指导书资源索引

完整的实验指导书（PDF 版与 1:1 Markdown 版）已保存在 `D:\HIT\CSAPP\Lab\实验指导书\`：

### 目录结构与快速导航
- **总览索引**：[README.md](file:///D:/HIT/CSAPP/Lab/实验指导书/README.md)
- **总体说明**：
  - [00_课程概况.md](file:///D:/HIT/CSAPP/Lab/实验指导书/00_课程概况.md)（课表与评分要求）
  - [01_作业提交说明.md](file:///D:/HIT/CSAPP/Lab/实验指导书/01_作业提交说明.md)（评测平台指南）
- **实验一：编写矩阵乘法（汇编入门与 SIMD 向量化）**
  - 汇总版：[实验1指导书汇总.md](file:///D:/HIT/CSAPP/Lab/实验指导书/实验1/实验1指导书汇总.md)
  - 分章节：[00_概述](file:///D:/HIT/CSAPP/Lab/实验指导书/实验1/00_实验概述.md)、[01_原理](file:///D:/HIT/CSAPP/Lab/实验指导书/实验1/01_实验原理.md)、[02_练习1:环境搭建](file:///D:/HIT/CSAPP/Lab/实验指导书/实验1/02_练习1.md)、[03_练习2:基础浮点乘法](file:///D:/HIT/CSAPP/Lab/实验指导书/实验1/03_练习2.md)、[04_练习3:SIMD向量化](file:///D:/HIT/CSAPP/Lab/实验指导书/实验1/04_练习3.md)、[05_练习4:深度优化与内存对齐](file:///D:/HIT/CSAPP/Lab/实验指导书/实验1/05_练习4.md)
- **实验二：存储层次结构与 Cache 优化**
  - 汇总版：[实验2指导书汇总.md](file:///D:/HIT/CSAPP/Lab/实验指导书/实验2/实验2指导书汇总.md)
  - 分章节：[00_概述](file:///D:/HIT/CSAPP/Lab/实验指导书/实验2/00_实验概述.md)、[01_原理](file:///D:/HIT/CSAPP/Lab/实验指导书/实验2/01_实验原理.md)、[02_练习1:Cache性能测试](file:///D:/HIT/CSAPP/Lab/实验指导书/实验2/02_练习1.md)、[03_练习2:Cache分块优化](file:///D:/HIT/CSAPP/Lab/实验指导书/实验2/03_练习2.md)、[04_练习3:预取优化](file:///D:/HIT/CSAPP/Lab/实验指导书/实验2/04_练习3.md)
- **实验三：指令级并行与多线程优化**
  - 汇总版：[实验3指导书汇总.md](file:///D:/HIT/CSAPP/Lab/实验指导书/实验3/实验3指导书汇总.md)
  - 分章节：[00_概述](file:///D:/HIT/CSAPP/Lab/实验指导书/实验3/00_实验概述.md)、[01_原理](file:///D:/HIT/CSAPP/Lab/实验指导书/实验3/01_实验原理.md)、[02_练习1:分支预测](file:///D:/HIT/CSAPP/Lab/实验指导书/实验3/02_练习1.md)、[03_练习2:循环展开与ILP](file:///D:/HIT/CSAPP/Lab/实验指导书/实验3/03_练习2.md)、[04_练习3:多线程并行](file:///D:/HIT/CSAPP/Lab/实验指导书/实验3/04_练习3.md)、[05_实验报告要求](file:///D:/HIT/CSAPP/Lab/实验指导书/实验3/05_实验报告要求.md)

> [!TIP]
> 后续执行具体任务时，Agent 请优先阅读对应章节的 `0x_练习x.md`，内容包含 100% 完整的源码修改提示、命令行参数与性能目标。

---

## 🛠️ 3. 实验环境与工具规范
- **运行环境**：课程指导书明确要求在 **Ubuntu 原生双系统（Ubuntu 22.04 LTS）** 下执行评测与运行，避免使用虚拟机或 WSL，以免硬件性能计数器（perf）和缓存测试数据失真。
- **构建工具**：`cmake`、`gcc`、`gfortran`、`gdb`、`make`。
- **汇编与指令集**：x86-64 AT&T 语法、AVX/AVX2 向量指令集（`vmovups`, `vfmadd231ps/pd` 等）。

---

## 🔄 4. 实验指导书自动同步规范（触发词响应）
- **触发指令**：当用户在对话中发送 **“更新拉取一次”** 或 **“更新一次”**（或类似更新指令）时：
- **执行动作**：Agent 必须直接运行动态同步脚本：
  ```powershell
  python "D:\HIT\CSAPP\Lab\实验指导书\sync_docs.py"
  ```
- **自动化能力**：该脚本会自动动态请求 `https://arch.p.cs-lab.top/search/search_index.json`，自动探测是否有新发布的实验（如实验4、实验5、实验6等），自动建立目录、下载新增图片素材、完成 1:1 Markdown 分章节与汇总转译，并刷新根目录 `README.md` 索引。

