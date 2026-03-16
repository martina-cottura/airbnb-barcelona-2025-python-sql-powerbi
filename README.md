# airbnb-barcelona-2025-python-sql-powerbi

# 🏙️ Mercado Turístico de Airbnb en Barcelona — 2025

> **Proyecto académico con simulación de consultoría** · Barcelona Market Analytics (BMA)  
> Análisis del mercado de viviendas turísticas para Mediterranean Urban Investments (MUI)

---

## 📋 Descripción

Análisis descriptivo del mercado de viviendas turísticas en **Airbnb Barcelona (2025)**, desarrollado como **proyecto académico** en el que simulamos el rol de una consultora de datos (**Barcelona Market Analytics — BMA**) y creamos un cliente ficticio (**Mediterranean Urban Investments — MUI**), una empresa de inversión inmobiliaria, como destinatario de los análisis y recomendaciones estratégicas.

Este marco de simulación profesional permitió estructurar el proyecto con una lógica de negocio real: definición de preguntas estratégicas, reuniones con stakeholders, entregables orientados a la toma de decisiones e insights accionables.

El proyecto integra tres tecnologías clave para construir un pipeline de datos completo: desde la extracción y limpieza de datos hasta la visualización interactiva de resultados.

```
Inside Airbnb (Sep 2025)
        ↓
  Python · Limpieza y transformación
        ↓
  SQL · Modelado dimensional 
        ↓
  Power BI · Dashboard analítico interactivo
```

---

## 🎯 Pregunta de negocio

> ¿Cuál es la dimensión y composición actual del mercado de viviendas de uso turístico de Airbnb en Barcelona en términos de volumen, precios, tipología de alojamiento y nivel de cumplimiento normativo?

---

## 📊 KPIs principales (scraping · 14 sep 2025)

| KPI | Valor |
|-----|-------|
| Total anuncios activos | **16.676** |
| Total hosts | **4.730** |
| % Anuncios multilisting | **91,24 %** |
| Precio promedio por noche | **186,86 €** |
| % Anuncios con licencia HUT | **54,12 %** |
| Disponibilidad media por anuncio | **227 días / año** |

---

## 🗂️ Estructura del repositorio

```
📁 airbnb-barcelona-2025/
│
├── 📁 data/
│   ├── raw/                        # Datos originales de Inside Airbnb
│   │   ├── listings.csv
│   │   ├── calendar.csv
│   │   └── neighbourhoods.csv
│   └── clean/                      # Datasets procesados listos para SQL
│       ├── listings_clean.csv
│       ├── calendar_limpio_filtrado.csv
│       └── neighbourhoods_clean.csv
│
├── 📁 notebooks/                   # Procesamiento en Python
│   ├── listings.ipynb
│   ├── calendar_limpio_filtrado.ipynb
│   ├── neighbourhoods.ipynb
│   └── listings_disp.ipynb         # Subconjunto con precio declarado
│
├── 📁 sql/                         # Modelado dimensional
│   ├── airbnb_barcelona_2025.sql   # Script DDL + DML completo
│   └── dump/                       # DUMP exportado desde MySQL Workbench
│
├── 📁 powerbi/
│   └── airbnb_barcelona_2025.pbix  # Dashboard interactivo
│
└── 📄 Informe_Técnico_BMA_2025.pdf # Informe técnico completo
```

---

## ⚙️ Stack tecnológico

| Herramienta | Uso |
|-------------|-----|
| **Python** + Pandas | Limpieza, transformación y EDA |
| **Jupyter / Anaconda** | Entorno de notebooks |
| **MySQL Workbench** | Modelado dimensional y carga de datos |
| **Power BI** | Visualización e insights estratégicos |

---

## 🗃️ Modelo de datos

Se implementó un **esquema de constelación de hechos (Fact Constellation Schema)**, dado que el proyecto contempla **dos procesos de negocio con granularidades distintas**, cada uno con su propia tabla de hechos y dimensiones asociadas.

```
  dim_host ──────────────────────────────────────────────┐
                                                         │
  dim_barrio ────────────── fact_anuncios ──── dim_tipo_alojamiento
                                  │
                                  │  (id_anuncio como FK)
                                  │
                          fact_disponibilidad
                                  │
                           Calendario (DAX)        dim_tipo_licencia ─── fact_anuncios
```

**Tablas de hechos — granularidades distintas:**

| Tabla | Granularidad | Registros |
|-------|-------------|-----------|
| `fact_anuncios` | 1 fila = 1 anuncio | 16.676 |
| `fact_disponibilidad` | 1 fila = 1 anuncio × 1 día | 6.086.742 |

> `fact_disponibilidad` no comparte dimensiones descriptivas con `fact_anuncios` en SQL — solo se vincula a ella por `id_anuncio` como clave foránea. En Power BI, su análisis temporal se realiza exclusivamente a través de la tabla **Calendario (DAX)**.

**Tablas de dimensiones** (asociadas a `fact_anuncios`):
- `dim_host` · `dim_barrio` · `dim_tipo_alojamiento` · `dim_tipo_licencia`

---

## 🔍 Fuente de datos

Los datos provienen de [**Inside Airbnb**](https://insideairbnb.com/get-the-data/), repositorio público que recopila información de Airbnb mediante web scraping ético.

- **Scraping:** 14 de septiembre de 2025
- **Cobertura:** 19.000+ anuncios en Barcelona (16.676 tras limpieza)
- **Calendario:** 14/09/2025 → 14/09/2026
- **Ámbito territorial:** 73 barrios · 10 distritos

> ⚠️ Los datos reflejan **oferta declarada**, no demanda real ni ocupación efectiva.

---

## 📈 Estructura del dashboard (Power BI)

| Página | Dimensión | Contenido |
|--------|-----------|-----------|
| **1** · ¿Dónde está la oferta? | What + Where | Mapa de burbujas, anuncios por zona, tipología |
| **2** · ¿Quién controla el mercado? | Who + How | Concentración de hosts, multilisting |
| **3** · Licencias y regulación | Why | Cumplimiento normativo, precio por licencia |
| **4** · Estacionalidad | When | Disponibilidad mensual, heatmap por distrito |

---

## 💡 Insights clave

1. **Mercado altamente profesionalizado** — el 91,2 % de los anuncios pertenecen a hosts con múltiples propiedades.
2. **Concentración geográfica extrema** — el 60 % de la oferta se ubica en Eixample y Ciutat Vella.
3. **Riesgo regulatorio significativo** — el 46 % de los anuncios opera sin licencia HUT.
4. **Modelo dominante: alojamiento completo** — el 99 % es vivienda completa o habitación privada.
5. **Premio de precio por legalidad** — anuncios con licencia alcanzan un precio promedio un 22 % superior.
6. **Estacionalidad marcada** — disponibilidad estable en otoño-invierno, reducida en primavera-verano.

---

## 🏗️ Cómo reproducir el proyecto

### 1. Preparación de datos (Python)
```bash
# Instalar dependencias
pip install pandas jupyter

# Ejecutar notebooks en orden
jupyter notebook notebooks/listings.ipynb
jupyter notebook notebooks/calendar_limpio_filtrado.ipynb
jupyter notebook notebooks/neighbourhoods.ipynb
```

### 2. Modelado en SQL
```sql
-- Ejecutar en MySQL Workbench
SOURCE sql/airbnb_barcelona_2025.sql;
```
> Requiere habilitar `local_infile` en MySQL y ajustar las rutas de los CSV en las sentencias `LOAD DATA LOCAL INFILE`.

### 3. Dashboard en Power BI
1. Abrir `powerbi/airbnb_barcelona_2025.pbix`
2. En **Obtener datos → MySQL**, conectar a `localhost` / `airbnb_barcelona_2025`
3. Instalar MySQL Connector/NET 8.0.29 si es necesario

---

## 👥 Equipo

| Nombre | Rol |
|--------|-----|
| Martina Cottura | Consultoría y análisis |
| Fernando Ferrari | Consultoría y análisis |
| Andrea Marques | Consultoría y análisis |
| Mario Paoloni | Consultoría y análisis |

**Cliente:** Mediterranean Urban Investments (MUI)  
**Consultora:** Barcelona Market Analytics (BMA)

---

## 📄 Licencia

Este proyecto fue desarrollado con fines académicos y de consultoría estratégica. Los datos provienen de Inside Airbnb bajo sus términos de uso públicos. No se incluyen datos personales identificables.

---

*Proyecto Integrador · Python | SQL | Power BI · 2025*
