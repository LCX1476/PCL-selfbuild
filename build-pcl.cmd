@echo off
REM 重新编译 PCL（含原版游戏下载功能）。需先改好源码，再双击本文件。
REM 依赖：.NET SDK 9.x、Roslyn 4.14 vbc、net48 引用程序集（见 说明.md）。
setlocal
set TMP=%~dp0.tmp
set TEMP=%~dp0.tmp
set MSBD=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe
set VBC=C:\tools\_ct\tasks\net472
set REFS=C:\tools\_ra48\build
set DN=C:\tools\dotnet9\dotnet.exe
set CLI_HOME=C:\tools\dotnethome
set NUGET=C:\tools\nuget

set DOTNET_CLI_HOME=%CLI_HOME%
set NUGET_PACKAGES=%NUGET%
set DOTNET_CLI_TELEMETRY_OPTOUT=1
set DOTNET_NOLOGO=1

cd /d "%~dp0PCL-main"
echo [1/2] 还原并编译 C# 子项目...
"%DN%" build MeloongCore\Wpf\MeloongCore.Wpf.csproj -c Release -v q || goto :err
"%DN%" build PCLCS\PCLCS.csproj -c Release -v q || goto :err

echo [2/2] 编译 VB 主程序...
"%MSBD%" "Plain Craft Launcher 2\Plain Craft Launcher 2.build.vbproj" -p:Configuration=Release -p:VbcToolPath=%VBC%\ -p:VbcToolExe=vbc.exe -p:TargetFrameworkRootPath=%REFS%\ -v:m -nologo || goto :err

copy /y "Plain Craft Launcher 2\obj\Release\Plain Craft Launcher 2.exe" "%~dp0PCL-下载版\Plain Craft Launcher 2.exe" >nul
echo.
echo 编译完成：%~dp0PCL-下载版\Plain Craft Launcher 2.exe
goto :eof

:err
echo.
echo 编译失败，请查看上面的错误信息。
exit /b 1
