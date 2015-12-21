:: Copyright 2014-2015 Viktor Szakats <https://github.com/vszakats>
:: See LICENSE.md

@echo off

set _NAM=%~n0
set _NAM=%_NAM:~3%
set _VER=%1
set _CPU=%2

setlocal
pushd "%_NAM%"

:: Build

set ZLIB_PATH=../../zlib
set OPENSSL_PATH=../../openssl
set OPENSSL_INCLUDE=%OPENSSL_PATH%/include
set OPENSSL_LIBPATH=%OPENSSL_PATH%
set OPENSSL_LIBS=-lssl -lcrypto
set LIBSSH2_PATH=../../libssh2
if "%_CPU%" == "win32" set ARCH=w32
if "%_CPU%" == "win64" set ARCH=w64
set CURL_CFLAG_EXTRAS=-DCURL_STATICLIB -fno-ident
set CURL_LDFLAG_EXTRAS=-static-libgcc

mingw32-make mingw32-clean
# Do not link WinIDN in 32-bit builds for Windows XP compatibility (missing normaliz.dll)
if "%_CPU%" == "win32" mingw32-make mingw32-rtmp-ssh2-ssl-sspi-zlib-ldaps-srp-ipv6
if "%_CPU%" == "win64" mingw32-make mingw32-rtmp-ssh2-ssl-sspi-zlib-ldaps-srp-ipv6-winidn

:: Download CA bundle
if not exist ..\ca-bundle.crt curl -R -fsS -L --proto-redir =https https://raw.githubusercontent.com/bagder/ca-bundle/master/ca-bundle.crt -o ..\ca-bundle.crt

:: Make steps for determinism

if exist lib\*.a   strip -p --enable-deterministic-archives -g lib\*.a
if exist lib\*.lib strip -p --enable-deterministic-archives -g lib\*.lib

python ..\peclean.py src\*.exe
python ..\peclean.py lib\*.dll

touch -c src/*.exe        -r CHANGES
touch -c lib/*.dll        -r CHANGES
touch -c ../ca-bundle.crt -r CHANGES
touch -c lib/*.a          -r CHANGES
touch -c lib/*.lib        -r CHANGES

:: Test run

src\curl.exe --version

:: Create package

set _BAS=%_NAM%-%_VER%-%_CPU%-mingw
if not "%APPVEYOR_REPO_BRANCH%" == "master" set _BAS=%_BAS%-test
set _DST=%TEMP%\%_BAS%

xcopy /y /s /q docs\*.              "%_DST%\docs\*.txt"
xcopy /y /s /q docs\*.html          "%_DST%\docs\"
xcopy /y /s /q docs\libcurl\*.html  "%_DST%\docs\libcurl\"
xcopy /y /s /q include\curl\*.h     "%_DST%\include\curl\"
 copy /y       lib\mk-ca-bundle.pl  "%_DST%\"
 copy /y       lib\mk-ca-bundle.vbs "%_DST%\"
 copy /y       CHANGES              "%_DST%\CHANGES.txt"
 copy /y       COPYING              "%_DST%\COPYING.txt"
 copy /y       README               "%_DST%\README.txt"
 copy /y       RELEASE-NOTES        "%_DST%\RELEASE-NOTES.txt"
xcopy /y /s    src\*.exe            "%_DST%\bin\"
xcopy /y /s    lib\*.dll            "%_DST%\bin\"
 copy /y       ..\ca-bundle.crt     "%_DST%\bin\curl-ca-bundle.crt"

 copy /y       ..\openssl\LICENSE   "%_DST%\LICENSE-openssl.txt"
 copy /y       ..\libssh2\COPYING   "%_DST%\COPYING-libssh2.txt"

if exist lib\*.a   xcopy /y /s lib\*.a   "%_DST%\lib\"
if exist lib\*.lib xcopy /y /s lib\*.lib "%_DST%\lib\"

unix2dos -k %_DST:\=/%/*.txt
unix2dos -k %_DST:\=/%/docs/*.txt

touch -c %_DST:\=/%/docs/examples     -r CHANGES
touch -c %_DST:\=/%/docs/libcurl/opts -r CHANGES
touch -c %_DST:\=/%/docs/libcurl      -r CHANGES
touch -c %_DST:\=/%/docs              -r CHANGES
touch -c %_DST:\=/%/include/curl      -r CHANGES
touch -c %_DST:\=/%/include           -r CHANGES
touch -c %_DST:\=/%/lib               -r CHANGES
touch -c %_DST:\=/%/bin               -r CHANGES
touch -c %_DST:\=/%                   -r CHANGES

call ..\pack.bat
call ..\upload.bat

popd
endlocal
