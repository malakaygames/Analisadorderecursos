@echo off
:: Configura UTF-8
chcp 65001 >nul
:: Configura fonte para suportar caracteres especiais
REG ADD HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Command Processor /v EnableExtensions /t REG_DWORD /d 1 /f >nul
reg add "HKEY_CURRENT_USER\Console" /v "CodePage" /t REG_DWORD /d 65001 /f >nul
reg add "HKEY_CURRENT_USER\Console" /v "FaceName" /t REG_SZ /d "Consolas" /f >nul

:: Verifica privilégios de administrador
NET SESSION >nul 2>&1
if %errorLevel% neq 0 (
    echo Executando como administrador...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

mode con cols=120 lines=40
title Diagnóstico do Sistema - %computername%
setlocal enabledelayedexpansion

:: Criar pasta temporária para testes se não existir
if not exist "%temp%\disktest" mkdir "%temp%\disktest"

:menu
cls
color 1F
echo ================================================================================================
echo                              DIAGNÓSTICO DO SISTEMA - %computername%
echo ================================================================================================
echo Data: %date% Hora: %time%
echo Usuário: %username%
echo.
echo    [1] Informações do Sistema              [4] Monitorização de Recursos
echo    [2] Informações de Hardware             [5] Ferramentas de Manutenção
echo    [3] Informações de Rede                 [6] Teste de Performance do Disco
echo    [7] Sair
echo.
echo ================================================================================================
set /p opcao="Escolha uma opção: "

if "%opcao%"=="1" goto sistema
if "%opcao%"=="2" goto hardware
if "%opcao%"=="3" goto rede
if "%opcao%"=="4" goto recursos
if "%opcao%"=="5" goto manutencao
if "%opcao%"=="6" goto testdisk
if "%opcao%"=="7" goto cleanup
goto menu

:sistema
cls
echo ================================================================================================
echo                                 INFORMAÇÕES DO SISTEMA
echo ================================================================================================
echo.
echo SISTEMA OPERACIONAL                        ^| DADOS DO COMPUTADOR
echo ------------------------------------------------------------------------------------------------
for /f "tokens=2 delims==" %%a in ('wmic OS get Caption /value') do set "OS=%%a"
for /f "tokens=2 delims==" %%a in ('wmic OS get Version /value') do set "VERSION=%%a"
echo Sistema: %OS%                              ^| Computador: %computername%
echo Versão: %VERSION%                          ^| Usuário: %username%
echo.
echo BIOS                                       ^| DOMÍNIO
echo ------------------------------------------------------------------------------------------------
for /f "tokens=2 delims==" %%a in ('wmic bios get SerialNumber /value') do set "SERIAL=%%a"
for /f "tokens=2 delims==" %%a in ('wmic COMPUTERSYSTEM get Domain /value') do set "DOMAIN=%%a"
echo Número de Série: %SERIAL%                  ^| Domínio: %DOMAIN%
echo.
pause
goto menu

:hardware
cls
echo ================================================================================================
echo                                 INFORMAÇÕES DE HARDWARE
echo ================================================================================================
echo.
echo PROCESSADOR                                ^| MEMÓRIA RAM
echo ------------------------------------------------------------------------------------------------
for /f "tokens=2 delims==" %%a in ('wmic cpu get Name /value') do set "CPU=%%a"
for /f "tokens=2 delims==" %%a in ('wmic MEMORYCHIP get Capacity /value') do set "RAM=%%a"
echo CPU: %CPU%                                 ^| RAM Total: %RAM% bytes
echo.
echo DISCO RÍGIDO                               ^| PLACA DE VÍDEO
echo ------------------------------------------------------------------------------------------------
for /f "tokens=2 delims==" %%a in ('wmic diskdrive get Size /value') do set "HDD=%%a"
for /f "tokens=2 delims==" %%a in ('wmic path win32_VideoController get Name /value') do set "GPU=%%a"
echo Tamanho: %HDD% bytes                       ^| GPU: %GPU%
echo.
pause
goto menu

:rede
cls
echo ================================================================================================
echo                                 INFORMAÇÕES DE REDE
echo ================================================================================================
echo.
echo CONFIGURAÇÃO IP                            ^| ADAPTADOR DE REDE
echo ------------------------------------------------------------------------------------------------
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do set "IP=%%a"
for /f "tokens=1 delims=" %%a in ('getmac') do set "MAC=%%a"
echo IP: %IP%                                   ^| MAC: %MAC%
echo.
echo DNS                                        ^| CONEXÃO
echo ------------------------------------------------------------------------------------------------
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"DNS"') do set "DNS=%%a"
ping -n 1 8.8.8.8 | findstr "tempo" > temp.txt
set /p PING=<temp.txt
del temp.txt
echo DNS: %DNS%                                 ^| %PING%
echo.
pause
goto menu

:recursos
cls
echo ================================================================================================
echo                                 MONITORIZAÇÃO DE RECURSOS
echo ================================================================================================
echo.
echo USO DE CPU                                 ^| MEMÓRIA EM USO
echo ------------------------------------------------------------------------------------------------
for /f "tokens=2 delims==" %%a in ('wmic cpu get loadpercentage /value') do set "CPU_LOAD=%%a"
for /f "tokens=2 delims==" %%a in ('wmic OS get FreePhysicalMemory /value') do set "FREE_RAM=%%a"
echo CPU: %CPU_LOAD%%%                          ^| Memória Livre: %FREE_RAM% KB
echo.
echo ESPAÇO EM DISCO                           ^| PROCESSOS
echo ------------------------------------------------------------------------------------------------
for /f "tokens=2 delims==" %%a in ('wmic logicaldisk where "DeviceID='C:'" get FreeSpace /value') do set "FREE_SPACE=%%a"
for /f "tokens=1" %%a in ('tasklist ^| find /c /v ""') do set "PROCESS_COUNT=%%a"
echo Espaço Livre: %FREE_SPACE% bytes          ^| Total de Processos: %PROCESS_COUNT%
echo.
pause
goto menu

:manutencao
cls
echo ================================================================================================
echo                                 FERRAMENTAS DE MANUTENÇÃO
echo ================================================================================================
echo.
echo    [1] Verificar Arquivos do Sistema       [4] Desfragmentar Disco
echo    [2] Verificar Disco                     [5] Voltar ao Menu Principal
echo    [3] Limpar Arquivos Temporários
echo.
set /p manut="Escolha uma opção: "

if "%manut%"=="1" (
    cls
    echo Verificando arquivos do sistema...
    sfc /scannow
    pause
    goto manutencao
)
if "%manut%"=="2" (
    cls
    echo Verificando disco C:...
    chkdsk C: /f /r
    pause
    goto manutencao
)
if "%manut%"=="3" (
    cls
    echo Limpando arquivos temporários...
    del /s /f /q %temp%\*.*
    echo Arquivos temporários removidos!
    pause
    goto manutencao
)
if "%manut%"=="4" (
    cls
    echo Desfragmentando disco C:...
    defrag C: /A /V
    pause
    goto manutencao
)
if "%manut%"=="5" goto menu
goto manutencao

:testdisk
cls
echo ================================================================================================
echo                                 TESTE DE PERFORMANCE DO DISCO
echo ================================================================================================
echo.
echo Selecione o tipo de teste:
echo    [1] Teste de Leitura
echo    [2] Teste de Escrita
echo    [3] Teste Completo (Leitura e Escrita)
echo    [4] Voltar ao Menu Principal
echo.
set /p disktest="Escolha uma opção: "

if "%disktest%"=="1" goto readtest
if "%disktest%"=="2" goto writetest
if "%disktest%"=="3" goto fulltest
if "%disktest%"=="4" goto menu
goto testdisk

:readtest
cls
echo ================================================================================================
echo                                    TESTE DE LEITURA
echo ================================================================================================
echo.
echo Criando arquivo de teste...
fsutil file createnew "%temp%\disktest\testfile" 104857600 >nul
echo Arquivo de teste de 100MB criado.
echo.
echo Iniciando teste de leitura...
echo.

set "start=%time%"

:: Teste de leitura - 5 iterações
for /l %%i in (1,1,5) do (
    echo Iteração %%i de 5...
    copy "%temp%\disktest\testfile" "%temp%\disktest\testread" >nul
    del "%temp%\disktest\testread" >nul
)

set "end=%time%"

:: Calcula o tempo
call :calculartempo
echo Teste de Leitura Concluído
echo ------------------------------------------------------------------------------------------------
echo Tamanho do arquivo: 100 MB
echo Número de iterações: 5
echo Tempo total: %duracao% segundos
echo Velocidade média de leitura: %velocidade% MB/s
echo.
del "%temp%\disktest\testfile" >nul
pause
goto testdisk

:writetest
cls
echo ================================================================================================
echo                                    TESTE DE ESCRITA
echo ================================================================================================
echo.
echo Iniciando teste de escrita...
echo.

set "start=%time%"

:: Teste de escrita - 5 iterações de 100MB cada
for /l %%i in (1,1,5) do (
    echo Iteração %%i de 5...
    fsutil file createnew "%temp%\disktest\testwrite%%i" 104857600 >nul
)

set "end=%time%"

:: Calcula o tempo
call :calculartempo
echo Teste de Escrita Concluído
echo ------------------------------------------------------------------------------------------------
echo Tamanho total escrito: 500 MB
echo Número de iterações: 5
echo Tempo total: %duracao% segundos
echo Velocidade média de escrita: %velocidade% MB/s
echo.
del "%temp%\disktest\testwrite*" >nul
pause
goto testdisk

:fulltest
cls
echo ================================================================================================
echo                               TESTE COMPLETO DE DISCO
echo ================================================================================================
echo.
echo TESTE DE LEITURA
echo ------------------------------------------------------------------------------------------------
call :readtest

echo TESTE DE ESCRITA
echo ------------------------------------------------------------------------------------------------
call :writetest
goto testdisk

:calculartempo
:: Converte tempo inicial para centésimos de segundo
set "start_h=%start:~0,2%"
set "start_m=%start:~3,2%"
set "start_s=%start:~6,2%"
set "start_c=%start:~9,2%"
set /a "start_ss=(((start_h*60)+start_m)*60+start_s)*100+start_c"

:: Converte tempo final para centésimos de segundo
set "end_h=%end:~0,2%"
set "end_m=%end:~3,2%"
set "end_s=%end:~6,2%"
set "end_c=%end:~9,2%"
set /a "end_ss=(((end_h*60)+end_m)*60+end_s)*100+end_c"

:: Calcula a diferença
set /a "duration=end_ss-start_ss"
set /a "duracao=duration/100"
set /a "velocidade=500/duracao"
goto :eof

:cleanup
:: Limpa arquivos temporários antes de sair
if exist "%temp%\disktest" rd /s /q "%temp%\disktest"
if exist temp.txt del temp.txt
exit
