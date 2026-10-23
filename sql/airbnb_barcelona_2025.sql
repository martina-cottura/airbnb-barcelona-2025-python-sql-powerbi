-- =====================================================
-- CREACIÓN DE BASE DE DATOS DEL PROYECTO
-- Proyecto: Análisis Airbnb Barcelona Septiembre 2025
-- =====================================================

CREATE DATABASE airbnb_barcelona_2025;

USE airbnb_barcelona_2025;

-- =====================================================
-- TABLA STAGING: staging_listings
-- Contendrá los datos crudos del CSV listings_clean
-- No tiene claves primarias ni foráneas
-- =====================================================

CREATE TABLE staging_listings (

    id_anuncio BIGINT,
    id_host BIGINT,
    nombre_host VARCHAR(255),
    cantidad_anuncios_host INT,
    cantidad_total_anuncios_host INT,
    barrio VARCHAR(255),
    latitud DECIMAL(10,6),
    longitud DECIMAL(10,6),
    tipo_alojamiento VARCHAR(100),
    capacidad INT,
    precio DECIMAL(10,2),
    noches_minimas INT,
    noches_maximas INT,
    puntuacion_general DECIMAL(3,2),
    puntuacion_ubicacion DECIMAL(3,2),
    puntuacion_valor DECIMAL(3,2),
    licencia VARCHAR(100),
    last_scraped DATE,
    precio_por_persona DECIMAL(10,2),
    tipo_host VARCHAR(100),
    tipo_licencia VARCHAR(100)

);

-- =====================================================
-- TABLA STAGING: staging_calendar
-- Contendrá disponibilidad diaria de cada anuncio
-- =====================================================

CREATE TABLE staging_calendar (

    id_anuncio BIGINT,
    fecha DATE,
    disponible INT,
    noches_minimas INT,
    noches_maximas INT

);

-- =====================================================
-- TABLA STAGING: staging_neighbourhoods
-- Contendrá relación entre zona y barrio
-- =====================================================

CREATE TABLE staging_neighbourhoods (

    zona VARCHAR(255),
    barrio VARCHAR(255)

);

-- =====================================================
-- DIMENSIÓN: dim_host
-- Información descriptiva de los anfitriones
-- =====================================================

CREATE TABLE dim_host (
    id_host BIGINT PRIMARY KEY,
    nombre_host VARCHAR(255),
    tipo_host VARCHAR(255),
    cantidad_anuncios_host INT,
    cantidad_total_anuncios_host INT
);

-- =====================================================
-- DIMENSIÓN: dim_barrio
-- Se crea una clave sustituta (id_barrio)
-- Permite relaciones más eficientes que usar texto
-- =====================================================

CREATE TABLE dim_barrio (
    id_barrio INT AUTO_INCREMENT PRIMARY KEY,
    barrio VARCHAR(100) NOT NULL,
    zona VARCHAR(100),
    latitud_centroide DECIMAL(10,7),
    longitud_centroide DECIMAL(10,7),
    UNIQUE (barrio)
);

-- =====================================================
-- DIMENSIÓN: dim_tipo_alojamiento
-- Clasificación del tipo de alojamiento
-- =====================================================

CREATE TABLE dim_tipo_alojamiento (
    id_tipo_alojamiento INT AUTO_INCREMENT PRIMARY KEY,
    tipo_alojamiento VARCHAR(100) UNIQUE,
    categoria VARCHAR(50)
);

-- =====================================================
-- DIMENSIÓN: dim_tipo_licencia
-- Permite categorizar licencias
-- =====================================================

CREATE TABLE dim_tipo_licencia (
    id_tipo_licencia INT AUTO_INCREMENT PRIMARY KEY,
    tipo_licencia VARCHAR(100) UNIQUE
);

-- =====================================================
-- TABLA DE HECHOS: fact_anuncios
-- Contiene métricas principales del anuncio
-- =====================================================

CREATE TABLE fact_anuncios (
    id_anuncio BIGINT PRIMARY KEY,

    id_host BIGINT,
    id_barrio INT,
    id_tipo_alojamiento INT,
    id_tipo_licencia INT,

    precio DECIMAL(10,2),
    capacidad INT,
    noches_minimas INT,
    noches_maximas INT,

    puntuacion_general DECIMAL(3,2),
    puntuacion_ubicacion DECIMAL(3,2),
    puntuacion_valor DECIMAL(3,2),

    latitud DECIMAL(10,7),
    longitud DECIMAL(10,7),

    FOREIGN KEY (id_host) REFERENCES dim_host(id_host),
    FOREIGN KEY (id_barrio) REFERENCES dim_barrio(id_barrio),
    FOREIGN KEY (id_tipo_alojamiento) REFERENCES dim_tipo_alojamiento(id_tipo_alojamiento),
    FOREIGN KEY (id_tipo_licencia) REFERENCES dim_tipo_licencia(id_tipo_licencia)
);

-- =====================================================
-- TABLA DE HECHOS: fact_disponibilidad
-- Disponibilidad diaria de cada anuncio
-- =====================================================

CREATE TABLE fact_disponibilidad (
    id_anuncio BIGINT,
    fecha DATE,
    disponible INT,
    noches_minimas INT,
    noches_maximas INT,

    PRIMARY KEY (id_anuncio, fecha),
    FOREIGN KEY (id_anuncio) REFERENCES fact_anuncios(id_anuncio)
);

-- =====================================================
-- CARGA MASIVA DE LOS CSV
-- =====================================================
-- Ya teniendo la estructura de las tablas, procedemos a cargar los datos de los CSV ya limpios, usando Load Data Local Infile. Para ello, habilitamos previamente los accesos

SHOW VARIABLES LIKE 'local_infile'; -- Como el resultado es OFF, lo cambiamos a ON
SET GLOBAL local_infile = 1;

-- Empezamos con la carga del CSV listings

LOAD DATA LOCAL INFILE 'C:/Users/andre/Desktop/Unicorn/PROYECTO INTEGRADOR/listings_clean.csv'
INTO TABLE staging_listings
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
  id_anuncio, id_host, nombre_host, cantidad_anuncios_host, cantidad_total_anuncios_host,
  barrio, latitud, longitud, tipo_alojamiento, capacidad,
  @precio, noches_minimas, noches_maximas,
  @pg, @pu, @pv, @lic, @ls, @ppp, tipo_host, tipo_licencia
)
SET
  precio = NULLIF(@precio,''),
  puntuacion_general = NULLIF(@pg,''),
  puntuacion_ubicacion = NULLIF(@pu,''),
  puntuacion_valor = NULLIF(@pv,''),
  licencia = NULLIF(@lic,''),
  last_scraped = NULLIF(@ls,''),
  precio_por_persona = NULLIF(@ppp,'');

-- Una vez cargados, hacemos una validacion de que se haya cargado correctamente.

SELECT 
    COUNT(*) AS total_filas,
    COUNT(id_anuncio) AS filas_con_id,
    COUNT(DISTINCT id_anuncio) AS anuncios_unicos
FROM staging_listings; 
-- El resultado fue 16676 filas para todos los counts hechos, con lo cual validamos la carga correcta del archivo.

-- Ahora continuamos con la carga del CSV de calendar

LOAD DATA LOCAL INFILE 'C:/Users/andre/Desktop/Unicorn/PROYECTO INTEGRADOR/calendar_limpio_filtrado.csv'
INTO TABLE staging_calendar
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    id_anuncio,
    @fecha,
    @disponible,
    noches_minimas,
    noches_maximas
)
SET
    -- Convertimos fecha vacía en NULL
    fecha = NULLIF(@fecha, ''),
    disponible = NULLIF(@disponible, '');


-- Validamos que se haya cargado correctamente el archivo y que tengamos el mismo numero de anuncios unicos que en la tabla staging_listings
SELECT 
    COUNT(*) AS total_filas,
    COUNT(id_anuncio) AS filas_con_id,
    COUNT(DISTINCT id_anuncio) AS anuncios_unicos
FROM staging_calendar;

-- El resultado obtenido fue 6,086,742 filas totales y filas con id; y un total de 16,676 anuncios unicos. Con estos resultados, validamos la correcta carga del archivo. 

-- Por ultimo, procedemos con la carga del CSV de neighbourhoods.

LOAD DATA LOCAL INFILE 'C:/Users/andre/Desktop/Unicorn/PROYECTO INTEGRADOR/neighbourhoods_clean.csv'
INTO TABLE staging_neighbourhoods
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    @zona,
    @barrio
)
SET
    zona   = NULLIF(@zona, ''),
    barrio = NULLIF(@barrio, '');
    
-- Validamos que la carga se haya hecho correctamente:

SELECT 
    COUNT(*) AS total_filas,
    COUNT(DISTINCT zona) AS total_zonas,
    COUNT(DISTINCT barrio) AS total_barrios
FROM staging_neighbourhoods;

-- El resultado obtenido fue 73 filas totales, que corresponden a los 73 barrios, con 10 zonas distintas. Con esto validamos la carga correcta del CSV.

-- =====================================================
-- Procedemos a transformar los datos y cargar el modelo dimensional, comenzando por las tablas de dimensiones y luego las de hechos.
-- PASO 1: Poblar dimensión barrio
-- Insertamos barrios únicos desde staging_neighbourhoods
-- =====================================================

INSERT INTO dim_barrio (barrio, zona)
SELECT DISTINCT
    s.barrio,
    n.zona
FROM staging_listings s
LEFT JOIN staging_neighbourhoods n
    ON s.barrio = n.barrio
WHERE s.barrio IS NOT NULL;

-- Validamos la carga de la tabla dim_barrio; ambas consultas deben coincidir en resultado:

SELECT COUNT(*) FROM dim_barrio;
SELECT COUNT(DISTINCT barrio) FROM staging_listings;

-- =====================================================
-- PASO 2: Poblar dimensión host
-- Insertamos hosts únicos
-- =====================================================

INSERT INTO dim_host (
    id_host,
    nombre_host,
    tipo_host,
    cantidad_anuncios_host,
    cantidad_total_anuncios_host
)
SELECT DISTINCT
    id_host,
    nombre_host,
    tipo_host,
    cantidad_anuncios_host,
    cantidad_total_anuncios_host
FROM staging_listings;

-- Validamos la carga de la tabla dim_host; ambas consultas deben coincidir en resultado:

SELECT COUNT(*) FROM dim_host;
SELECT COUNT(DISTINCT id_host) FROM staging_listings;

-- =====================================================
-- PASO 3: Poblar dimensión tipo de alojamiento
-- Extraemos los tipos únicos desde staging_listings
-- =====================================================

INSERT INTO dim_tipo_alojamiento (tipo_alojamiento)
SELECT DISTINCT tipo_alojamiento
FROM staging_listings
WHERE tipo_alojamiento IS NOT NULL;

-- Procedemos a la asignación de categorías del alojamiento:

SET SQL_SAFE_UPDATES = 0;

UPDATE dim_tipo_alojamiento
SET categoria =
    CASE
        WHEN tipo_alojamiento = 'Entire home/apt' THEN 'Completo'
        ELSE 'Habitación'
    END;

SET SQL_SAFE_UPDATES = 1;

-- ===============================
-- PASO 4: Poblar dimensión tipo licencia 
-- Extraemos tipos únicos de licencias
-- ===============================

INSERT INTO dim_tipo_licencia (tipo_licencia)
SELECT DISTINCT tipo_licencia
FROM staging_listings
WHERE tipo_licencia IS NOT NULL;

-- =====================================================
-- PASO 5: Poblar tabla de hechos fact_anuncios
-- Snapshot del mercado (septiembre 2025)
-- =====================================================

INSERT INTO fact_anuncios (
    id_anuncio,
    id_host,
    id_barrio,
    id_tipo_alojamiento,
    id_tipo_licencia,
    precio,
    capacidad,
    noches_minimas,
    noches_maximas,
    puntuacion_general,
    puntuacion_ubicacion,
    puntuacion_valor,
    latitud,
    longitud
)
SELECT
    s.id_anuncio,
    s.id_host,
    b.id_barrio,
    t.id_tipo_alojamiento,
    l.id_tipo_licencia,
    s.precio,
    s.capacidad,
    s.noches_minimas,
    s.noches_maximas,
    s.puntuacion_general,
    s.puntuacion_ubicacion,
    s.puntuacion_valor,
    s.latitud,
    s.longitud
FROM staging_listings s
LEFT JOIN dim_barrio b
    ON s.barrio = b.barrio
LEFT JOIN dim_tipo_alojamiento t
    ON s.tipo_alojamiento = t.tipo_alojamiento
LEFT JOIN dim_tipo_licencia l
    ON s.tipo_licencia = l.tipo_licencia;

-- =====================================================
-- PASO 6: Calcular el centroide del barrio
-- Añadimos estas columnas, características de cada barrio
-- =====================================================

SET SQL_SAFE_UPDATES = 0;

UPDATE dim_barrio b
JOIN (
    SELECT
        id_barrio,
        AVG(latitud) AS lat_prom,
        AVG(longitud) AS lon_prom
    FROM fact_anuncios
    GROUP BY id_barrio
) t
ON b.id_barrio = t.id_barrio
SET
    b.latitud_centroide = t.lat_prom,
    b.longitud_centroide = t.lon_prom;
    
SET SQL_SAFE_UPDATES = 1;
    
-- =====================================================
-- PASO 7: Poblar tabla de hechos fact_disponibilidad
-- Snapshot del mercado (septiembre 2025)
-- =====================================================

LOAD DATA LOCAL INFILE 'C:/Users/andre/Desktop/Unicorn/PROYECTO INTEGRADOR/calendar_limpio_filtrado.csv'
INTO TABLE fact_disponibilidad
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    id_anuncio,
    @fecha,
    @disponible,
    noches_minimas,
    noches_maximas
)
SET
    -- Convertimos fecha y disponible vacías en NULL
    fecha = NULLIF(@fecha, ''),
    disponible = NULLIF(@disponible, '');
    
-- ===============================
-- Paso 8: VALIDACIONES FINALES DE TABLAS DE HECHOS
-- ===============================

SELECT COUNT(*) FROM fact_anuncios;
SELECT COUNT(*) FROM staging_listings;
-- Al obtener el mismo resultado, 16,676 anuncios, lo damos por validado.

SELECT COUNT(*) FROM fact_disponibilidad;
SELECT COUNT(*) FROM staging_calendar;
-- Al obtener el mismo resultado, 6,086,742 filas, lo damos por validado.

-- De esta manera, hemos conseguido completar nuestra base de datos, modelar y normalizar para que posteriormente en PowerBI el modelo sea más eficiente.