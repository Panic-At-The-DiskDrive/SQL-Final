# SQL - Final

## Crearás tu propia base de datos, en la cual se implementará el modelo relacional para representar procesos basados en un modelo de negocio propio, con dataset público o ficticio. Implementarás los procesos técnicos que requiere el mantenimiento de una base de datos.

1. **Clonar el repositorio**  
   ```bash
   git clone https://github.com/Panic-At-The-DiskDrive/SQL-Final
   ```

2. **Entrar a la carpeta del proyecto**  
   ```bash
   cd SQL-Final
   ```

## Objetivos
+ Crear una base de datos relacional, basada en un modelo de negocio.

+ Desarrollar objetos que permitan el mantenimiento de la base de datos.

+ Implementar consultas SQL que permitan la generación de informes.

## Requisitos
1) La base de datos debe contener al menos:  

+ 15 tablas, entre las cuales debe haber al menos 1 tabla de hechos,  2 tablas transaccionales.
+ 5 vistas..
+ 2 funciones    
+ 2 stored procedure.
+ 2 trigger 
  
2) El documento debe contener:  

+ Introducción
+ Objetivo
+ Situación problemática
+ Modelo de negocio
+ Diagrama de entidad relación
+ Listado de tablas con descripción de estructura (columna, descripción, tipo de datos, tipo de clave)
+ Scripts de creación de cada objeto de la base de datos
+ Scripts de inserción de datos
+ Informes generados en base a la información de la base
+ Herramientas y tecnologías usadas
+ Futuras líneas

## Recomendaciones
1)  Permitir comentarios en el archivo.

2) SCRIPT: 

+ Tablas
+ Vistas
+ Funciones
+ Store procedure
+ Trigger
+ Inserción de datos

## Contenidos adicionales  

1) El nombre de las tablas es en SINGULAR (por buenas practicas) 

2) create_at y update_at: estos son datos que no deberian ir en dicha tabla, sino en una tabla de bitacora, tabla de hecho, etc.

### Criterios de evaluación
+ Funcional

1) Presenta la documentación en formato PDF solicitada, la cual muestra toda la información referida a su proyecto final. Incluye un Sumario inicial el cual brinda un panorama general de todo el contenido del documento PDF y hasta permite acceder a cada apartado a través de un hipervínculo. La sección Introducción contiene todo lo referente a la explicación de su proyecto final. Es conciso y no tiene párrafos de relleno. La sección Objetivo, tiene un detalle de lo que el proyecto busca cubrir en dicho apartado, reverenciando al proyecto en sí y a las diferentes aristas que son cross-funcional al mismo (información contable, de logística, analítica, etcétera).

2) El apartado Situación Problemática describe correctamente la necesidad de implementar una base de datos sobre el modelo de proyecto elegido y qué brechas puede solucionar a través de dicha implementación. El apartado Modelo de Negocio describe la información abstracta de la organización que utiliza esta solución. Esta descripción puede estar realizada en un modelo textual o a través de uno o más gráficos, siendo cualquiera de estos coincidentes con el proyecto presentado.

3) El diagrama E-R (Entidad-Relación) representa de manera fiel la estructura de base de datos que visualizamos a través del Esquema generado a partir de los archivos .SQL. Despliega las diferentes Entidades incluidas en el proyecto y sus relaciones, coincidiendo todo con la información generada a partir del Script de creación del Esquema. El Diagrama E-R fue presentado en formato gráfico dentro del documento PDF o en un archivo externo acompañando la documentación, y fue explicado o mencionado dentro del documento PDF. <---------------> El apartado Listado de Tablas representa de manera fiel todas las Entidades incluidas en el script de creación del Esquema de datos. Por cada Entidad se encuentran descritos cada uno de sus campos (o columnas), el tipo de datos de cada uno de éstos, y el tipo de clave utilizado. También se combinan las claves únicas, foráneas e índices en aquellas tablas (Entidades) que las requieren.

4) Los Stored Procedures y Funciones creadas por el estudiante cuentan con una mínima descripción que explica su funcionalidad.

+ Tecnico:

1) Se incluyen dos scripts del tipo archivo .SQL, cuyos nombres referencian claramente qué función cumple cada uno de ellos.

2) Se ejecuta el script inicial (creación de objetos de la bb.dd.) y el mismo no presenta problemas (arroja errores) al ejecutarse. Este script de creación genera correctamente todas las entidades en la base de datos, y sus diferentes relaciones. Además se incluyen en el esquema de bb.dd. (15 o + tablas, dentro de estas 1 tabla de Hechos, 2 tablas transaccionales, 5 o + Vistas, 2 o + Stored Procedures, 2 o + Triggers, 2 o + Funciones creadas por el estudiante).

3) Se ejecuta el segundo script del proyecto (inserción de registros) y el mismo no presenta problemas (no arroja errores) al ejecutarse. El script de inserción genera correctamente información (registros) en cada una de las tablas (Entidades). Dicha información es concisa y no esta repetida con el mero hecho de generar volumen de datos. Posterior  al proceso de inserción de datos, se ejecutan las Vistas y Stored Procedures, los cuales brindan información resultante en pantalla a partir de los datos generados.  
  
+ Analítico:

1) El estudiante utilizó una herramienta de analítica de datos para extraer información de su modelo de datos generado. Armó un informe donde refleja un análisis a partir de la información generada en su bb.dd.

2) Dicho informe se presenta en un archivo PDF independiente o está incluido en el documento PDF funcional y explica mínimamente qué datos fueron analizados.

3) El informe fue generado a partir de una aplicación de software como ser Microsoft Excel, Tableau, Microsoft Power BI, u otra aplicación de software similar.  

---

## Tecnologías utilizadas

- **SQL**
---