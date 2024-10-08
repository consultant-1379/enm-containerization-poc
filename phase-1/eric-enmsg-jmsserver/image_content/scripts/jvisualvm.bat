@echo off
rem -------------------------------------------------------------------------
rem jvusualvm script for Windows
rem -------------------------------------------------------------------------
rem
rem A script for running jvusualvm with the remoting-jmx libraries on the classpath.

rem $Id$
setlocal EnableExtensions EnableDelayedExpansion

@if not "%ECHO%" == ""  echo %ECHO%
@if "%OS%" == "Windows_NT" setlocal

if "%OS%" == "Windows_NT" (
  set "DIRNAME=%~dp0%"
) else (
  set DIRNAME=.\
)

pushd %DIRNAME%..
set "RESOLVED_JBOSS_HOME=%CD%"
popd

if "x%JBOSS_HOME%" == "x" (
  set "JBOSS_HOME=%RESOLVED_JBOSS_HOME%"
)

pushd "%JBOSS_HOME%"
set "SANITIZED_JBOSS_HOME=%CD%"
popd

if "%RESOLVED_JBOSS_HOME%" NEQ "%SANITIZED_JBOSS_HOME%" (
    echo WARNING JBOSS_HOME may be pointing to a different installation - unpredictable results may occur.
)

set DIRNAME=

rem Setup JBoss specific properties
if "x%JAVA_HOME%" == "x" (
  echo JAVA_HOME is not set. Unable to locate the jars needed to run jvisualvm.
  goto END
)

rem are we on 6.1.0 or up ?
if exist "%JBOSS_HOME%\bin\client\jboss-cli-client.jar" (
  set CLASSPATH="%JBOSS_HOME%\bin\client\jboss-cli-client.jar"
) else (
  rem Set default module root paths
  if "x%JBOSS_MODULEPATH%" == "x" (
      set "JBOSS_MODULEPATH=%JBOSS_HOME%\modules"
  )
  set CLASSPATH=
  call :SearchForJars "!JBOSS_MODULEPATH!\org\jboss\remoting3\remoting-jmx\main"
  call :SearchForJars "!JBOSS_MODULEPATH!\org\jboss\remoting3\main"
  call :SearchForJars "!JBOSS_MODULEPATH!\org\jboss\logging\main"
  call :SearchForJars "!JBOSS_MODULEPATH!\org\jboss\xnio\main"
  call :SearchForJars "!JBOSS_MODULEPATH!\org\jboss\xnio\nio\main"
  call :SearchForJars "!JBOSS_MODULEPATH!\org\jboss\sasl\main"
  call :SearchForJars "!JBOSS_MODULEPATH!\org\jboss\marshalling\main"
  call :SearchForJars "!JBOSS_MODULEPATH!\org\jboss\marshalling\river\main"
  call :SearchForJars "!JBOSS_MODULEPATH!\org\jboss\as\cli\main"
  call :SearchForJars "!JBOSS_MODULEPATH!\org\jboss\staxmapper\main"
  call :SearchForJars "!JBOSS_MODULEPATH!\org\jboss\as\protocol\main"
  call :SearchForJars "!JBOSS_MODULEPATH!\org\jboss\dmr\main"
  call :SearchForJars "!JBOSS_MODULEPATH!\org\jboss\as\controller-client\main"
  call :SearchForJars "!JBOSS_MODULEPATH!\org\jboss\threads\main"
  call :SearchForJars "!JBOSS_MODULEPATH!\org\jboss\as\controller\main"
)

rem echo %CLASSPATH%

"%JAVA_HOME%\bin\jvisualvm.exe" "-cp " "%CLASSPATH%"
:END
goto :EOF

:SearchForJars
set NEXT_MODULE_DIR=%1
call :DeQuote NEXT_MODULE_DIR
pushd %NEXT_MODULE_DIR%
for %%j in (*.jar) do call :ClasspathAdd "%NEXT_MODULE_DIR%\%%j"
popd
goto :EOF

:ClasspathAdd
set NEXT_JAR=%1
call :DeQuote NEXT_JAR
set CLASSPATH=%CLASSPATH%;%NEXT_JAR%
goto :EOF

:DeQuote
for /f "delims=" %%A in ('echo %%%1%%') do set %1=%%~A
goto :EOF

:EOF
