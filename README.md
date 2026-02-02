# Meltano Project

Este proyecto utiliza Meltano, una herramienta open source para construir un pipeline de datos (ELT) basada en plugins y ejecución por línea de comandos.

Meltano se ejecuta siempre mediante comandos y no funciona como un servicio en segundo plano por defecto. Cada ejecución es explícita y controlada por el usuario o por un orquestador externo.

Meltano sigue el patrón ELT, no ETL:

* Extract → tap-* → emite registros Singer (JSON)
* Load → target-* → guarda los registros en la base de datos destino
* Transform → dbt → lee las tablas que ya están en la base de datos y crea vistas o tablas finales

## Entorno virtual

Se recomienda usar un entorno virtual de Python para el proyecto, de forma que las dependencias no interfieran con otras instalaciones del sistema:

```bash
py -3.11 -m venv .venv
.venv\Scripts\activate
python -m pip install --upgrade pip
pip install meltano
```

## Inicialización del proyecto

```bash
meltano init meltano_project
```

Este comando genera la estructura base necesaria para trabajar con Meltano y prepara el proyecto para añadir extractores, cargadores, transformaciones y orquestación.

Meltano crea los siguientes archivos y carpetas:

* `.meltano/`: Directorio interno de Meltano donde se almacenan la base de datos del proyecto, los entornos virtuales de los plugins y la información de estado y ejecución.
* `meltano.yml`: Archivo principal de configuración del proyecto. Aquí se definen:
  * Plugins (extractors, loaders, transformers, utilities)
  * Configuración por entorno (`dev`, `staging`, `prod`)
  * Parámetros de conexión y selección de datos
* `README.md`: Documentación del proyecto.
* `requirements.txt`: Archivo opcional para dependencias adicionales del proyecto que no forman parte de los plugins de Meltano.
* `extract/`: Carpeta destinada a lógica personalizada relacionada con la extracción de datos.
* `load/`: Carpeta destinada a lógica personalizada relacionada con la carga de datos.
* `transform/`: Carpeta utilizada normalmente para transformaciones, por ejemplo proyectos dbt integrados con Meltano.
* `analyze/`: Espacio para análisis posteriores sobre los datos cargados.
* `notebook/`: Carpeta pensada para notebooks (por ejemplo Jupyter) para exploración y análisis de datos.
* `orchestrate/`: Utilizada cuando se integra Meltano con herramientas de orquestación como Airflow o Dagster.
* `output/`: Carpeta para salidas locales del proyecto. Incluye su propio `.gitignore`.
* `.gitignore`: Configuración básica para evitar versionar archivos generados automáticamente, como `.meltano/`.

## Entornos

Durante la inicialización, Meltano crea automáticamente los siguientes entornos:

* `dev`
* `staging`
* `prod`

Estos entornos permiten definir configuraciones distintas (credenciales, destinos, parámetros) sin duplicar proyectos ni configuraciones.

## Hub de Meltano

Meltano se apoya principalmente en el ecosistema Singer, un estándar open source para el movimiento de datos entre sistemas. Singer define una especificación común que establece cómo los extractores emiten los datos, cómo los loaders los consumen y cómo se comunican entre sí de forma desacoplada.

En el Meltano Hub [https://hub.meltano.com/](https://hub.meltano.com/) se pueden encontrar:

* Extractors: fuentes de datos (APIs, bases de datos, ficheros, etc.)
* Loaders: destinos de datos (Postgres, Snowflake, BigQuery, etc.)
* Utilities / Tools: herramientas adicionales (dbt, Airbyte bridge, great_expectations, etc.)

## Extractors

En Meltano, los extractors son los componentes encargados de extraer datos desde una fuente y emitirlos en un formato estándar Singer, que luego será consumido por un loader para cargarlos en un destino.

Para esta prueba de concepto utilizaremos:

* PostgreSQL como fuente relacional
* Una API REST pública como fuente externa

Nos posicionamos en el directorio del proyecto Meltano:

```bash
cd meltano_project
```

A partir de aquí se irán añadiendo y configurando los extractores necesarios mediante la CLI de Meltano.

Cada extractor se declara en el proyecto y queda versionado en el fichero `meltano.yml`.

### PostgreSQL

Extractor para bases de datos PostgreSQL:

```bash
meltano add tap-postgres
```

### REST API

Para consumir APIs REST genéricas utilizaremos el extractor `tap-rest-api-msdk`:

```bash
meltano add tap-rest-api-msdk
```

### Inicialización de las fuentes de datos

Levantamos los servicios definidos en el `docker-compose.yml`, que incluyen PostgreSQL y su interfaz gráfica:

```bash
docker compose up -d --build
```

El script de inicialización de PostgreSQL crea la base de datos y la tabla `users` con dos usuarios por defecto.

#### PostgreSQL

Nos conectamos a PostgreSQL utilizando pgAdmin, accesible desde el puerto expuesto en el `docker-compose`.

Credenciales:

* Usuario: `meltano`
* Contraseña: `meltano`
* Base de datos: `meltano_postgres_db`

#### API REST

Como fuente de datos vía API REST utilizaremos el endpoint público:

```
https://jsonplaceholder.typicode.com/users
```

Este endpoint devuelve una lista de usuarios en formato JSON con campos como `id`, `name` y `email`.

### Configuración de los extractors

#### Postgres

Podemos inspeccionar los parámetros admitidos por el extractor:

```bash
meltano config list tap-postgres
```

Configuramos la conexión al contenedor PostgreSQL:

```bash
meltano config set tap-postgres host localhost
meltano config set tap-postgres port 5432
meltano config set tap-postgres user meltano
meltano config set tap-postgres password meltano
meltano config set tap-postgres database meltano_postgres_db
```

* Estos comandos únicamente guardan la configuración en `meltano.yml`.

Podemos comprobar la configuración:

```bash
meltano config print tap-postgres
```

Y validar la conexión:

```bash
meltano config test tap-postgres
```

Si ejecutamos directamente el extractor:

```bash
meltano invoke tap-postgres
```

El extractor:

* Se conecta a la base de datos
* Descubre todos los esquemas y tablas accesibles
* Emite mensajes Singer en formato JSON

Por defecto, el extractor incluye tablas internas del sistema, por lo que debemos limitar su alcance.

Listamos streams y columnas:

```bash
meltano select tap-postgres --list
```

Limpiamos selecciones previas:

```bash
meltano select tap-postgres --clear
```

Seleccionamos únicamente la tabla `users` del esquema `public`:

```bash
meltano select tap-postgres "public-users"
```

Ejecutamos el extractor ya filtrado:

```bash
meltano invoke tap-postgres
```

#### API REST

Configuramos la URL base:

```bash
meltano config set tap-rest-api-msdk api_url https://jsonplaceholder.typicode.com
```

La definición del stream se realiza directamente en `meltano.yml`, ya que la configuración de streams del `tap-rest-api-msdk` no puede expresarse completamente desde la CLI.

```yaml
streams:
  - name: users
    path: /users
    primary_keys: [id]
    records_path: $[*]
```

* `name`: nombre lógico del stream dentro de Meltano. Se utilizará para nombrar tablas, esquemas y referencias posteriores (por ejemplo en dbt).
* `path`: ruta relativa del endpoint respecto a `api_url`. En este caso construye la URL final `https://jsonplaceholder.typicode.com/users`.
* `primary_keys`: campos que identifican de forma única cada registro. Son obligatorios para que el extractor pueda emitir correctamente estados Singer y permitir cargas idempotentes.
* `records_path`: expresión JSONPath que indica dónde se encuentran los registros dentro de la respuesta JSON. `$[*]` significa que la respuesta es una lista plana y que cada elemento del array es un registro.

## Loader

Añadimos el loader PostgreSQL:

```bash
meltano add target-postgres
```

Configuramos el destino:

```bash
meltano config set target-postgres host localhost
meltano config set target-postgres port 5432
meltano config set target-postgres user meltano
meltano config set target-postgres password meltano
meltano config set target-postgres database meltano_postgres_db
```

Ambos extractores cargan sus datos en la misma base de datos, cada uno en su propio esquema.

## Transformer

Meltano se integra con dbt para la fase de transformación. dbt trabaja exclusivamente con tablas ya existentes en la base de datos.

Es importante remarcar que dbt no consume datos directamente de los extractores ni de Singer, sino exclusivamente de tablas ya persistidas en la base de datos.

Añadimos dbt:

```bash
meltano add --plugin-type transformer dbt-postgres
```

Configuramos dbt para usar la misma base de datos que el loader:

```bash
meltano config set dbt-postgres host localhost
meltano config set dbt-postgres port 5432
meltano config set dbt-postgres user meltano
meltano config set dbt-postgres password meltano
meltano config set dbt-postgres dbname meltano_postgres_db
meltano config set dbt-postgres schema public
```

* Es obligatorio que dbt use la misma base de datos que los loaders. PostgreSQL no permite referencias entre bases de datos distintas dentro de una misma consulta SQL.
* dbt no lee Singer, ni conoce los extractores o loaders. dbt solo ejecuta SQL sobre tablas ya cargadas.

Para que dbt pueda referenciar las tablas creadas por los loaders, es necesario declararlas explícitamente como sources.
Estas definiciones indican a dbt qué tablas existen previamente, en qué base de datos y esquema se encuentran, y bajo qué nombre lógico se van a utilizar.

Las sources se definen en `transform/models/sources.yml`:

```yaml
version: 2

sources:
  - name: tap_postgres
    database: meltano_postgres_db
    schema: tap_postgres
    tables:
      - name: users

  - name: tap_rest_api_msdk
    database: meltano_postgres_db
    schema: tap_rest_api_msdk
    tables:
      - name: users
```

Donde:

* `database`: base de datos donde el loader ha creado las tablas
* `schema`: esquema asociado a cada extractor
* `tables`: tablas disponibles para ser consumidas por dbt

Estas definiciones permiten a dbt validar la existencia de las tablas y resolver correctamente las dependencias antes de ejecutar los modelos.

Configuramos finalmente el modelo en `transform/models/unify.sql`:

```sql
select name, email
from {{ source('tap_postgres', 'users') }}

union

select name, email
from {{ source('tap_rest_api_msdk', 'users') }}
```

## Ejecución final del pipeline ELT

Definimos un job que encadena todo el flujo:

```bash
meltano job add full_pipeline --tasks "[tap-postgres target-postgres, tap-rest-api-msdk target-postgres, dbt-postgres:run]"
```

Ejecutamos el pipeline completo:

```bash
meltano run full_pipeline
```

Resultado final:

* Los datos de PostgreSQL y de la API REST se cargan en la misma base de datos.
* dbt crea una vista llamada `unify`.
* La vista contiene `name` y `email` unificados desde ambas fuentes, sin duplicados.

Este flujo representa un pipeline ELT completo y funcional usando Meltano, Singer y dbt sobre PostgreSQL.

## Conclusiones

En este proyecto se ha buscado construir un pipeline ELT completo usando Meltano, combinando datos de una base de datos PostgreSQL y de un endpoint REST, y luego transformarlos con dbt para generar una vista unificada de usuarios. La idea era tener un flujo sencillo: extraer, cargar y transformar. Sin embargo, durante el proceso se han encontrado varias limitaciones y aspectos a considerar.

Una de las primeras dificultades fue con los extractores y loaders. No todos los destinos son soportados de forma confiable; por ejemplo, no fue posible usar MongoDB como loader. Además, la configuración de streams en el extractor de API REST no se puede completar completamente desde la CLI, obligando a modificar manualmente el archivo `meltano.yml`. Esto muestra que Meltano es bastante rígido y que algunas configuraciones complejas requieren intervención directa en los archivos de proyecto.

Otro punto importante es que Meltano está orientado a ELT, no a ETL. No permite transformar los datos antes de cargarlos, así que toda la limpieza, combinación o consolidación debe hacerse sobre tablas ya persistidas en la base de datos destino usando SQL. Esto genera redundancia: se cargan tablas separadas por cada extractor y luego se combinan en una vista final, lo que puede ser ineficiente si los datos son grandes o si se repite esta lógica en varios pipelines. Además, dbt no interactúa con los extractores ni con los mensajes Singer; solo trabaja sobre tablas ya cargadas, lo que refuerza esta naturaleza estrictamente ELT de Meltano.

Por otro lado, herramientas como NiFi resultaron más flexibles para ciertos flujos de datos. Con NiFi se puede configurar visualmente la extracción, transformación y carga, controlar los campos que se necesitan, y crear rutas condicionales sin tener que tocar archivos de configuración manualmente. Esto hace que para pipelines que no son puramente analíticos, o que requieren ETL clásico, Meltano pueda sentirse limitado y menos intuitivo en comparación con alternativas modernas.

En resumen, Meltano funciona bien para pipelines analíticos donde el destino es un data warehouse y las transformaciones se realizan en SQL, especialmente si se busca versionar todo como código. Sin embargo, para integraciones con fuentes o destinos no relacionales, o para flujos donde se necesita transformar antes de cargar, otras herramientas como NiFi pueden ofrecer una experiencia más directa y flexible.