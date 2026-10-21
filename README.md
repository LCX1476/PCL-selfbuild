# PCL 自编译版 —— 恢复原版游戏下载

> 上游项目：[Meloong-Git/PCL](https://github.com/Meloong-Git/PCL)
> 本仓库只做一件事：把官方因合规关闭的 **原版游戏下载** 功能重新打开，并给出可直接运行的构建。

## 下载

| 文件 | 说明 |
|---|---|
| `Plain Craft Launcher 2.exe` | 单文件启动器，5,868,032 字节，md5 `866eaffebe870f43dd50590f94b32b09` |
| `说明.md` | 改动点、编译方法、验证记录 |
| `build-pcl.cmd` | 一键重编脚本（需要本机编译环境，见下） |
| `patch/ModSecret.diff` | 唯一的源码改动 |

双击 exe 即可运行，不依赖 .NET SDK 或 Visual Studio。

## 改了什么

整个下载引擎在源码里本来就完整，官方只是用一个常量把它关掉了。本构建只翻转了这一个常量：

`Plain Craft Launcher 2/Modules/ModSecret.vb:18`

```diff
-    Public Const RestrictMcDownload As Boolean = True
+    Public Const RestrictMcDownload As Boolean = False
```

改完之后，这些位置的分支自动走回正常逻辑（它们本来就是 `If RestrictMcDownload ... Else ...` 的两条路）：

- `Pages/PageDownload/PageDownloadInstall.xaml.vb:17-21` —— 下载页不再挂「关闭下载」任务
- `Pages/PageDownload/PageDownloadModify.vb:315` —— 「安装新版本」卡片重新可见
- `Pages/PageDownload/Resource/PageDownloadCompDetail.xaml.vb:275` —— 整合包详情页的版本选择
- `Modules/ModModpack.vb:11,88` —— 整合包安装不再直接抛异常

## 验证记录

在本机（Windows 11）实跑通过：

1. 「下载 → 原版游戏」正常列出全部版本（最新版、快照、全部正式版列表）；
2. 点进某个版本能看到 Forge / NeoForge / Fabric / OptiFine 选项，而不是「关闭下载」报错页；
3. 点「开始下载」真实下载并安装成功：
   - `versions/<版本>/<版本>.jar`（41,483,720 字节，正常 zip）
   - `versions/<版本>/<版本>.json`（`type=release`、114 个 libraries、assetIndex 有效）
   - `versions/<版本>/PCL/Setup.ini` 里 `State:1`（PCL 自己的安装完成标记）
4. 依赖库与资源文件按 BMCLAPI 镜像优先正常补齐。

## 已知限制（源码本身自带，不是本构建引入的）

上游开源分支的 `ModSecret.vb` 把敏感串删空了（文件头写明「部分代码已被删除」），因此：

- **微软正版登录不可用**（`OAuthClientId` 为空）——用离线登录；
- **CurseForge 搜索不可用**（`CurseForgeAPIKey` 为空）；
- 原版下载**不受影响**，它只依赖 Mojang 公开清单。

想恢复这两项，可以在启动前设置环境变量 `PCL_MS_CLIENT_ID` / `PCL_CURSEFORGE_API_KEY`（源码第 10、12 行读的就是这两个变量）。

## 自己编译

本仓库的 `build-pcl.cmd` 是当时用的脚本，编译环境（全部免管理员）：

| 组件 | 用途 |
|---|---|
| .NET SDK 9.x | 编 `MeloongCore` / `PCLCS`（C# 13，SDK 8 会报 `CS1617`） |
| Roslyn 4.14 `vbc.exe` | 给系统自带 Framework MSBuild 提供新 VB 编译器 |
| `Microsoft.NETFramework.ReferenceAssemblies.net48` | 本机没有 net48 开发包时提供引用程序集 |
| `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe` | 编 WPF 主程序（SDK 自带 MSBuild 跑不了经典 WPF 工程） |

关键坑：

1. 主工程必须用 **Framework MSBuild**，SDK 的 MSBuild 缺 `PresentationBuildTasks`，会报 `MC1000 mscorlib 无法解析`；
2. 三条 `ProjectReference` 要换成对 DLL 的 `Reference`（见 `Plain Craft Launcher 2.build.vbproj`），并补 `netstandard` / `System.Runtime` facade，否则 MarkupCompilePass2 报 `BC30652`；
3. `-p:` 而不是 `/p:`（Git Bash 会改写后者）。

## 许可

上游代码与许可归 [Meloong-Git/PCL](https://github.com/Meloong-Git/PCL) 所有，请遵守其许可；本仓库仅提供一份自行编译的构建与补丁，供个人使用。
