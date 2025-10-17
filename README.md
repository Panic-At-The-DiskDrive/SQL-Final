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
+ Deberás entregar los avances correspondiente a la segunda entrega de tu proyecto final, incluyendo lo presentado y ajustado en la primera entrega.

## Requisitos
+ Listado de Vistas más una descripción detallada, su objetivo, y qué tablas las componen.

+ Listado de Funciones que incluyan una descripción detallada, el objetivo para la cual fueron creadas y qué datos o tablas manipulan y/o son implementadas.

+ Listado de Stored Procedures con una descripción detallada, qué objetivo o beneficio aportan al proyecto, y las tablas que lo componen y/o tablas con las que interactúa.

+ Un archivo .sql que contenga:

1) Script de inserción de datos en las bases.

2) Si se insertan datos mediante importación, agregar el paso a paso de éste en el DOC PDF más los archivos con el contenido a importar, en el formato que corresponda.

3) Script de creación de Vistas, Funciones, Stored Procedures y Triggers.

## Recomendaciones
+ Permitir comentarios en el archivo.

## Contenidos adicionales  

1) El nombre de las tablas es en SINGULAR (por buenas practicas) 

2) create_at y update_at: estos son datos que no deberian ir en dicha tabla, sino en una tabla de bitacora, tabla de hecho, etc.

### Criterios de evaluación
+ Funcional
Presenta la documentación en formato PDF solicitada, la cual muestra toda la información referida a su proyecto.

1) Junto al contenido original, se adiciona el listado de Vistas creadas a partir de las tablas de su proyecto, su descripción, objetivos de uso, y qué tablas componen dichas Vistas.

2) También se detalla el listado de Funciones personalizadas, su descripción, objetivos de uso, y qué tablas las conforman o qué función aplican sobre la información.

3) Se incluye el listado de Stored Procedures creados, con su descripción, los objetivos de uso, y qué tablas lo componen o sobre cuáles tablas impacta el uso de éstos.

4) Se detalla el listado de Triggers creados, una descripción de su funcionalidad, objetivos y/o sobre qué tablas y/o situaciones se accionan.

5) Todas las secciones agregadas son concisas y no tienen párrafos de relleno.

6) El resto de la información anterior, se mantiene fiel respecto a su primera presentación parcial, o se incluyeron mejoras o detalle de tablas adicionales que se crearon a partir de nuevos conocimientos adquiridos.

+ Tecnico:
Se incluye un script del tipo archivo .SQL, cuyo nombre referencia qué función cumple.

1) Se ejecuta el script inicial de creación de Vistas, Stored Procedures, Triggers y Funciones Personalizadas sin presentar problemas al ejecutarse. El script genera correctamente los objetos de bb.dd. descritos en el documento presentado.

2) Se ejecuta el segundo script, el cual genera registros en las tablas de datos para luego poder ejecutar Stored Procedures, Funciones personalizadas, Vistas y/o disparar Triggers y llegar a resultados óptimos a partir de los registros generados.

---

## Tecnologías utilizadas

- **SQL**
---