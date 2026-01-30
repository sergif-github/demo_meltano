# Meltano Project

Este proyecto utiliza **Meltano**, una herramienta open source para construir pipelines de datos (ELT/ETL) basada en plugins y ejecución por línea de comandos.

Meltano se ejecuta siempre mediante comandos y no funciona como un servicio en segundo plano por defecto.

## Entorno virtual

Se recomienda usar un entorno virtual de Python para el proyecto:

```bash
python -m venv .venv
.venv\Scripts\activate
pip install --upgrade pip
pip install meltano
```

## Inicialización del proyecto

```bash
meltano init meltano_project
```

Este comando genera la estructura base necesaria para trabajar con Meltano y prepara el proyecto para añadir extractores, cargadores, transformaciones y orquestación.

Meltano crea los siguientes archivos y carpetas:

### `.meltano/`

Directorio interno de Meltano donde se almacenan la base de datos del proyecto, los entornos virtuales de los plugins y la información de estado y ejecución, y que no debe modificarse manualmente ni versionarse en Git.

### `meltano.yml`

Archivo principal de configuración del proyecto en el que se definen los plugins utilizados, la configuración por entorno (`dev`, `staging`, `prod`) y los parámetros de ejecución del pipeline.

### `README.md`

Documentación del proyecto.

### `requirements.txt`

Archivo opcional para dependencias adicionales del proyecto (no incluye plugins de Meltano).

### `extract/`

Carpeta destinada a lógica personalizada relacionada con la extracción de datos.

### `load/`

Carpeta destinada a lógica personalizada relacionada con la carga de datos.

### `transform/`

Carpeta utilizada normalmente para transformaciones, por ejemplo proyectos **dbt** integrados con Meltano.

### `analyze/`

Espacio para análisis posteriores sobre los datos cargados.

### `notebook/`

Carpeta pensada para notebooks (por ejemplo Jupyter) para exploración y análisis de datos.

### `orchestrate/`

Utilizada cuando se integra Meltano con herramientas de orquestación como Airflow o Dagster.

### `output/`

Carpeta para salidas locales del proyecto. Incluye su propio `.gitignore`.

### `.gitignore`

Configuración básica para evitar versionar archivos generados automáticamente, como `.meltano/`.

## Entornos

Durante la inicialización, Meltano crea automáticamente los siguientes entornos:

* `dev`
* `staging`
* `prod`

Estos entornos permiten definir configuraciones distintas (credenciales, destinos, parámetros) sin duplicar proyectos.
