@echo off
setlocal enabledelayedexpansion

REM Script para gestionar el ciclo de vida de contenedores Docker
REM Debe ejecutarse como administrador

title Docker PostgreSQL Management

REM Verificar si se esta ejecutando como administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Este script requiere privilegios de administrador.
    echo Por favor, ejecute como administrador.
    pause
    exit /b 1
)

REM Obtener la ruta actual del script
set "SCRIPT_DIR=%~dp0"
set "COMPOSE_FILE=%SCRIPT_DIR%docker-compose.yml"
set "DATA_DIR=%SCRIPT_DIR%data"

REM Verificar que el archivo docker-compose.yml existe
if not exist "%COMPOSE_FILE%" (
    echo [ERROR] No se encuentra el archivo docker-compose.yml en la carpeta actual.
    echo         El archivo debe estar en: %COMPOSE_FILE%
    pause
    exit /b 1
)

:menu
cls
echo ======================================================
echo          GESTOR DE DOCKER POSTGRESQL
echo ======================================================
echo.
echo  [1] DEPLOY      - Descargar imagen y levantar contenedor
echo  [2] START       - Iniciar contenedor existente
echo  [3] STOP        - Detener contenedor
echo  [4] DESTROY     - Eliminar contenedor y recursos asociados
echo  [5] PURGE_DATA  - Eliminar datos persistentes (reset DB)
echo  [6] STATUS      - Ver estado de contenedores
echo  [7] EXIT        - Salir
echo.
echo ======================================================
echo.

set /p option="Seleccione una opcion: "

if "%option%"=="1" goto deploy
if "%option%"=="2" goto start
if "%option%"=="3" goto stop
if "%option%"=="4" goto destroy
if "%option%"=="5" goto purge
if "%option%"=="6" goto status
if "%option%"=="7" goto end

echo Opcion invalida. Intente nuevamente.
timeout /t 2 >nul
goto menu

:deploy
echo.
echo [INFO] Descargando imagen y desplegando contenedor...
docker-compose -f "%COMPOSE_FILE%" up -d
if %errorlevel% neq 0 (
    echo [ERROR] Fallo el despliegue del contenedor.
) else (
    echo [SUCCESS] Contenedor desplegado correctamente.
)
pause
goto menu

:start
echo.
echo [INFO] Iniciando contenedor existente...
docker-compose -f "%COMPOSE_FILE%" start
if %errorlevel% neq 0 (
    echo [ERROR] Fallo el inicio del contenedor.
) else (
    echo [SUCCESS] Contenedor iniciado correctamente.
)
pause
goto menu

:stop
echo.
echo [INFO] Deteniendo contenedor...
docker-compose -f "%COMPOSE_FILE%" stop
if %errorlevel% neq 0 (
    echo [ERROR] Fallo la detencion del contenedor.
) else (
    echo [SUCCESS] Contenedor detenido correctamente.
)
pause
goto menu

:destroy
echo.
echo [WARNING] Esta accion eliminara el contenedor y sus recursos asociados.
set /p confirm="Confirmar eliminacion (S/N): "
if /i "%confirm%"=="S" (
    echo [INFO] Eliminando contenedor y recursos...
    docker-compose -f "%COMPOSE_FILE%" down --rmi all
    if %errorlevel% neq 0 (
        echo [ERROR] Fallo la eliminacion del contenedor.
    ) else (
        echo [SUCCESS] Contenedor y recursos eliminados correctamente.
    )
) else (
    echo Operacion cancelada.
)
pause
goto menu

:purge
echo.
echo [WARNING] Esta accion eliminara TODOS los datos persistentes de la base de datos.
echo           La proxima vez que inicie el contenedor, tendra una base de datos vacia.
set /p confirm="Confirmar eliminacion de datos (S/N): "
if /i "%confirm%"=="S" (
    echo [INFO] Deteniendo contenedor...
    docker-compose -f "%COMPOSE_FILE%" down
    
    echo [INFO] Eliminando volumen de datos...
    if exist "%DATA_DIR%" (
        echo [INFO] Borrando directorio: %DATA_DIR%
        rmdir /s /q "%DATA_DIR%"
        if %errorlevel% neq 0 (
            echo [ERROR] Fallo al eliminar los datos. Intente cerrar todas las aplicaciones.
        ) else (
            echo [SUCCESS] Datos eliminados correctamente.
        )
    ) else (
        echo [WARNING] Directorio de datos no encontrado en: %DATA_DIR%
    )
) else (
    echo Operacion cancelada.
)
pause
goto menu

:status
echo.
echo [INFO] Estado de contenedores:
docker ps -a | findstr postgres-db
echo.
echo [INFO] Informacion detallada:
docker inspect postgres-db 2>nul || echo Contenedor no encontrado.
pause
goto menu

:end
echo.
echo Saliendo...
timeout /t 1 >nul
exit /b 0