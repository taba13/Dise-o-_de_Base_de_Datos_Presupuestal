# Diseño de Base de Datos Presupuestal

🧠 Descripción general
Este script SQL define el modelo de datos para la gestión presupuestal de la Universidad de Manizales. Incluye la creación de tablas, relaciones, restricciones, vistas e índices que soportan las operaciones de planeación, seguimiento y ejecución del presupuesto institucional.

📁 Contenido del script
Creación de secuencias implícitas mediante SERIAL

Tablas principales:

CENTROS_UTILIDAD

RUBROS

PERIODOS_PRESUPUESTALES

USUARIOS

PRESUPUESTOS

TIPOS_MOVIMIENTO

TRASLADOS_PRESUPUESTALES

MOVIMIENTOS_PRESUPUESTALES

HISTORICO_CAMBIOS_AUDITORIA

Vista:

V_PRESUPUESTOS_CON_DISPONIBLE (para cálculo automático del presupuesto disponible)

Función y trigger de auditoría:

fn_registrar_cambios_auditoria()

trg_auditoria_centros_utilidad (comentado como ejemplo)

Índices para mejora de rendimiento en consultas

🔐 Integridad y Auditoría
Se implementan restricciones CHECK, FOREIGN KEY y UNIQUE en todas las tablas críticas.

Auditoría integrada con una tabla HISTORICO_CAMBIOS_AUDITORIA, lista para activarse por medio de triggers específicos.

Todos los movimientos presupuestales están auditados con valores de saldo antes y después.

⚙️ Consideraciones técnicas
Compatible con PostgreSQL

Usa tipos como NUMERIC(19,4) para precisión en operaciones financieras

Asegura unicidad lógica en presupuestos por centro + rubro + periodo

La vista V_PRESUPUESTOS_CON_DISPONIBLE puede usarse para reportes o dashboards

🚀 Instrucciones de uso
Crear una base de datos en PostgreSQL:

sql
Copiar
Editar
CREATE DATABASE presupuesto_um;
Ejecutar el script:

bash
Copiar
Editar
psql -U [usuario] -d presupuesto_um -f "modelo (1).sql"
(Opcional) Activar auditoría en las tablas deseadas agregando los triggers.

📊 Extensiones posibles
Integración con Power BI para visualización del estado presupuestal.

Backend con Python o Node.js para manejar los movimientos.

API RESTful para interactuar con los datos desde aplicaciones administrativas.

