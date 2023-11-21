chcp 65001
cd %~dp0

@echo off
echo 即将启动GoogleServiceJson下载本地服务器，在打包完成前请勿关闭
@echo on
python GoogleServiceJsonFile.py
if %ERRORLEVEL% NEQ 0 (
@echo off
    echo 调用python出错，请检查环境变量中”系统变量“(注意不是单个个人用户变量)是否已有python路径，并在设置后重启Unity
    echo 如果没有安装Python请先安装
@echo on
)

if %ERRORLEVEL% NEQ 0 pause