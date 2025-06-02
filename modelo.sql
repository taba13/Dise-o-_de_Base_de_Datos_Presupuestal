-- Creación de Secuencias (Aunque SERIAL lo hace implícitamente, es bueno conocerlas)
-- CREATE SEQUENCE seq_centro_utilidad_id START 1;
-- ... y así para las demás tablas con SERIAL

-- Tabla: CENTROS_UTILIDAD
CREATE TABLE CENTROS_UTILIDAD (
    id_centro_utilidad SERIAL PRIMARY KEY,
    codigo_centro VARCHAR(50) UNIQUE NOT NULL,
    nombre_centro VARCHAR(255) NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITHOUT TIME ZONE
);

-- Tabla: RUBROS
CREATE TABLE RUBROS (
    id_rubro SERIAL PRIMARY KEY,
    codigo_rubro VARCHAR(50) UNIQUE NOT NULL,
    nombre_rubro VARCHAR(255) NOT NULL,
    descripcion TEXT,
    tipo_rubro VARCHAR(20) NOT NULL CHECK (tipo_rubro IN ('INGRESO', 'EGRESO')), -- O según la clasificación necesaria
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITHOUT TIME ZONE
);

-- Tabla: PERIODOS_PRESUPUESTALES
CREATE TABLE PERIODOS_PRESUPUESTALES (
    id_periodo SERIAL PRIMARY KEY,
    nombre_periodo VARCHAR(100) UNIQUE NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado VARCHAR(20) DEFAULT 'Abierto' NOT NULL CHECK (estado IN ('Abierto', 'Cerrado', 'Aprobado', 'En Ejecucion')),
    fecha_creacion TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITHOUT TIME ZONE,
    CONSTRAINT chk_fechas_periodo CHECK (fecha_fin >= fecha_inicio)
);

-- Tabla: USUARIOS (Ejemplo básico)
CREATE TABLE USUARIOS (
    id_usuario SERIAL PRIMARY KEY,
    nombre_usuario VARCHAR(100) UNIQUE NOT NULL,
    nombre_completo VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    rol VARCHAR(50) CHECK (rol IN ('Administrador', 'Gestor Presupuestal', 'Consultor', 'Aprobador')),
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITHOUT TIME ZONE
);

-- Tabla: PRESUPUESTOS
CREATE TABLE PRESUPUESTOS (
    id_presupuesto SERIAL PRIMARY KEY,
    id_periodo INT NOT NULL,
    id_centro_utilidad INT NOT NULL,
    id_rubro INT NOT NULL,
    monto_asignado NUMERIC(19, 4) NOT NULL DEFAULT 0.00,
    monto_comprometido NUMERIC(19, 4) NOT NULL DEFAULT 0.00,
    monto_ejecutado NUMERIC(19, 4) NOT NULL DEFAULT 0.00,
    -- monto_disponible se calcula en la aplicación o con una vista/función.
    -- O se puede usar un campo generado si la lógica es simple:
    -- monto_disponible NUMERIC(19, 4) GENERATED ALWAYS AS (monto_asignado - monto_comprometido - monto_ejecutado) STORED,
    fecha_creacion TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITHOUT TIME ZONE,
    CONSTRAINT fk_presupuesto_periodo FOREIGN KEY (id_periodo) REFERENCES PERIODOS_PRESUPUESTALES(id_periodo),
    CONSTRAINT fk_presupuesto_centro_utilidad FOREIGN KEY (id_centro_utilidad) REFERENCES CENTROS_UTILIDAD(id_centro_utilidad),
    CONSTRAINT fk_presupuesto_rubro FOREIGN KEY (id_rubro) REFERENCES RUBROS(id_rubro),
    CONSTRAINT uq_presupuesto_rubro_centro_periodo UNIQUE (id_periodo, id_centro_utilidad, id_rubro),
    CONSTRAINT chk_monto_asignado CHECK (monto_asignado >= 0),
    CONSTRAINT chk_monto_comprometido CHECK (monto_comprometido >= 0),
    CONSTRAINT chk_monto_ejecutado CHECK (monto_ejecutado >= 0)
);

-- Vista para calcular el monto disponible (alternativa a columna generada)
CREATE OR REPLACE VIEW V_PRESUPUESTOS_CON_DISPONIBLE AS
SELECT
    p.*,
    (p.monto_asignado - p.monto_comprometido - p.monto_ejecutado) AS monto_disponible
FROM
    PRESUPUESTOS p;


-- Tabla: TIPOS_MOVIMIENTO
CREATE TABLE TIPOS_MOVIMIENTO (
    id_tipo_movimiento SERIAL PRIMARY KEY,
    codigo_movimiento VARCHAR(50) UNIQUE NOT NULL, -- Ej: 'ASIGNACION_INICIAL', 'TRASLADO_SALIDA', 'TRASLADO_ENTRADA', 'COMPROMISO', 'EJECUCION_GASTO', 'LIBERACION_COMPROMISO', 'AJUSTE_AUMENTO', 'AJUSTE_DISMINUCION'
    nombre_movimiento VARCHAR(100) NOT NULL,
    descripcion TEXT,
    -- Naturaleza indica qué campos del presupuesto afecta y cómo
    -- 'A': Aumenta monto_asignado
    -- 'C': Aumenta monto_comprometido
    -- 'L': Disminuye monto_comprometido (liberación)
    -- 'E': Aumenta monto_ejecutado (y usualmente disminuye comprometido si lo había)
    -- 'R': Reduce monto_asignado
    -- 'X': Anulación/Reverso de ejecución (reduce ejecutado)
    afecta_asignado CHAR(1) DEFAULT 'N' NOT NULL CHECK (afecta_asignado IN ('A', 'R', 'N')), -- Aumenta, Reduce, Nada
    afecta_comprometido CHAR(1) DEFAULT 'N' NOT NULL CHECK (afecta_comprometido IN ('A', 'R', 'N')), -- Aumenta, Reduce, Nada
    afecta_ejecutado CHAR(1) DEFAULT 'N' NOT NULL CHECK (afecta_ejecutado IN ('A', 'R', 'N')) -- Aumenta, Reduce, Nada
);

-- Insertar tipos de movimiento básicos
INSERT INTO TIPOS_MOVIMIENTO (codigo_movimiento, nombre_movimiento, descripcion, afecta_asignado, afecta_comprometido, afecta_ejecutado) VALUES
('ASIGNACION_INICIAL', 'Asignación Inicial de Presupuesto', 'Carga inicial del presupuesto aprobado.', 'A', 'N', 'N'),
('AJUSTE_AUMENTO', 'Ajuste de Aumento Presupuestal', 'Incremento al monto asignado.', 'A', 'N', 'N'),
('AJUSTE_DISMINUCION', 'Ajuste de Disminución Presupuestal', 'Reducción al monto asignado.', 'R', 'N', 'N'),
('COMPROMISO', 'Registro de Compromiso', 'Reserva de presupuesto para un gasto futuro.', 'N', 'A', 'N'),
('LIBERACION_COMPROMISO', 'Liberación de Compromiso', 'Liberación de un monto previamente comprometido y no ejecutado.', 'N', 'R', 'N'),
('EJECUCION_DIRECTA', 'Ejecución Directa de Gasto', 'Registro de un gasto sin compromiso previo.', 'N', 'N', 'A'),
('EJECUCION_CON_COMPROMISO', 'Ejecución de Gasto con Compromiso', 'Registro de un gasto que estaba comprometido.', 'N', 'R', 'A'),
('ANULACION_EJECUCION', 'Anulación de Ejecución de Gasto', 'Reverso de una ejecución de gasto.', 'N', 'N', 'R'),
('TRASLADO_SALIDA', 'Traslado Presupuestal (Salida)', 'Envío de fondos a otro presupuesto.', 'R', 'N', 'N'), -- Reduce el asignado del origen
('TRASLADO_ENTRADA', 'Traslado Presupuestal (Entrada)', 'Recepción de fondos desde otro presupuesto.', 'A', 'N', 'N'); -- Aumenta el asignado del destino


-- Tabla: TRASLADOS_PRESUPUESTALES
CREATE TABLE TRASLADOS_PRESUPUESTALES (
    id_traslado SERIAL PRIMARY KEY,
    id_presupuesto_origen INT NOT NULL,
    id_presupuesto_destino INT NOT NULL,
    monto_trasladado NUMERIC(19, 4) NOT NULL,
    fecha_solicitud DATE DEFAULT CURRENT_DATE NOT NULL,
    fecha_aprobacion DATE,
    fecha_ejecucion DATE, -- Fecha en que se hacen efectivos los movimientos
    estado_traslado VARCHAR(20) DEFAULT 'Solicitado' NOT NULL CHECK (estado_traslado IN ('Solicitado', 'Aprobado', 'Rechazado', 'Ejecutado', 'Anulado')),
    justificacion TEXT NOT NULL,
    observaciones_aprobacion TEXT,
    id_usuario_solicitante INT,
    id_usuario_aprobador INT,
    referencia_documento VARCHAR(100),
    fecha_creacion TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITHOUT TIME ZONE,
    CONSTRAINT fk_traslado_presupuesto_origen FOREIGN KEY (id_presupuesto_origen) REFERENCES PRESUPUESTOS(id_presupuesto),
    CONSTRAINT fk_traslado_presupuesto_destino FOREIGN KEY (id_presupuesto_destino) REFERENCES PRESUPUESTOS(id_presupuesto),
    CONSTRAINT fk_traslado_usuario_solicitante FOREIGN KEY (id_usuario_solicitante) REFERENCES USUARIOS(id_usuario),
    CONSTRAINT fk_traslado_usuario_aprobador FOREIGN KEY (id_usuario_aprobador) REFERENCES USUARIOS(id_usuario),
    CONSTRAINT chk_monto_trasladado CHECK (monto_trasladado > 0),
    CONSTRAINT chk_origen_destino_diferentes CHECK (id_presupuesto_origen <> id_presupuesto_destino)
);

-- Tabla: MOVIMIENTOS_PRESUPUESTALES (Registro Histórico Detallado)
CREATE TABLE MOVIMIENTOS_PRESUPUESTALES (
    id_movimiento SERIAL PRIMARY KEY,
    id_presupuesto INT NOT NULL, -- Presupuesto afectado
    id_tipo_movimiento INT NOT NULL,
    monto NUMERIC(19, 4) NOT NULL,
    saldo_anterior_asignado NUMERIC(19,4) NOT NULL, -- Informativo para auditoría
    saldo_anterior_comprometido NUMERIC(19,4) NOT NULL, -- Informativo para auditoría
    saldo_anterior_ejecutado NUMERIC(19,4) NOT NULL, -- Informativo para auditoría
    saldo_posterior_asignado NUMERIC(19,4) NOT NULL, -- Informativo para auditoría
    saldo_posterior_comprometido NUMERIC(19,4) NOT NULL, -- Informativo para auditoría
    saldo_posterior_ejecutado NUMERIC(19,4) NOT NULL, -- Informativo para auditoría
    fecha_movimiento DATE DEFAULT CURRENT_DATE NOT NULL, -- Fecha real del evento económico/presupuestal
    fecha_registro TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL, -- Fecha de inserción en BD
    descripcion TEXT,
    id_usuario_responsable INT,
    referencia_documento VARCHAR(100), -- Ej: Nro de factura, solicitud de traslado, orden de compra, Nro de traslado
    id_traslado_asociado INT NULL, -- Si el movimiento es parte de un traslado aprobado
    CONSTRAINT fk_movimiento_presupuesto FOREIGN KEY (id_presupuesto) REFERENCES PRESUPUESTOS(id_presupuesto),
    CONSTRAINT fk_movimiento_tipo FOREIGN KEY (id_tipo_movimiento) REFERENCES TIPOS_MOVIMIENTO(id_tipo_movimiento),
    CONSTRAINT fk_movimiento_usuario FOREIGN KEY (id_usuario_responsable) REFERENCES USUARIOS(id_usuario),
    CONSTRAINT fk_movimiento_traslado FOREIGN KEY (id_traslado_asociado) REFERENCES TRASLADOS_PRESUPUESTALES(id_traslado) ON DELETE SET NULL,
    CONSTRAINT chk_monto_movimiento_positivo CHECK (monto >= 0) -- Permitir monto 0 para ciertos casos si es necesario, sino > 0
);

-- Tabla: HISTORICO_CAMBIOS_AUDITORIA (Para auditoría general de cambios en cualquier tabla)
-- Esta tabla se suele poblar mediante triggers.
CREATE TABLE HISTORICO_CAMBIOS_AUDITORIA (
    id_auditoria SERIAL PRIMARY KEY,
    schema_name NAME NOT NULL,
    table_name NAME NOT NULL,
    user_name NAME,
    action_tstamp TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    action CHAR(1) NOT NULL CHECK (action IN ('I', 'D', 'U', 'T')), -- Insert, Delete, Update, Truncate
    original_data JSONB, -- Datos antiguos para UPDATE y DELETE
    new_data JSONB,      -- Datos nuevos para INSERT y UPDATE
    query TEXT          -- Opcional: la consulta que causó el cambio
);

-- Ejemplo de función de trigger para auditoría (simplificado)
CREATE OR REPLACE FUNCTION fn_registrar_cambios_auditoria()
RETURNS TRIGGER AS $$
DECLARE
    v_old_data JSONB := NULL;
    v_new_data JSONB := NULL;
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
    ELSIF (TG_OP = 'DELETE') THEN
        v_old_data := to_jsonb(OLD);
    ELSIF (TG_OP = 'INSERT') THEN
        v_new_data := to_jsonb(NEW);
    END IF;

    INSERT INTO HISTORICO_CAMBIOS_AUDITORIA (
        schema_name,
        table_name,
        user_name,
        action_tstamp,
        action,
        original_data,
        new_data
    )
    VALUES (
        TG_TABLE_SCHEMA::TEXT,
        TG_TABLE_NAME::TEXT,
        session_user::TEXT,
        CURRENT_TIMESTAMP,
        LEFT(TG_OP, 1),
        v_old_data,
        v_new_data
    );

    RETURN NEW; -- O OLD para DELETE
END;
$$ LANGUAGE plpgsql;

-- Para aplicar el trigger a una tabla (ejemplo para CENTROS_UTILIDAD):
/*
CREATE TRIGGER trg_auditoria_centros_utilidad
AFTER INSERT OR UPDATE OR DELETE ON CENTROS_UTILIDAD
FOR EACH ROW EXECUTE FUNCTION fn_registrar_cambios_auditoria();
*/
-- Se debería crear un trigger similar para cada tabla que se quiera auditar.

-- Índices para mejorar el rendimiento de las consultas comunes:
CREATE INDEX idx_presupuestos_periodo ON PRESUPUESTOS(id_periodo);
CREATE INDEX idx_presupuestos_centro_utilidad ON PRESUPUESTOS(id_centro_utilidad);
CREATE INDEX idx_presupuestos_rubro ON PRESUPUESTOS(id_rubro);

CREATE INDEX idx_movimientos_presupuesto ON MOVIMIENTOS_PRESUPUESTALES(id_presupuesto);
CREATE INDEX idx_movimientos_tipo ON MOVIMIENTOS_PRESUPUESTALES(id_tipo_movimiento);
CREATE INDEX idx_movimientos_fecha ON MOVIMIENTOS_PRESUPUESTALES(fecha_movimiento);
CREATE INDEX idx_movimientos_traslado_asociado ON MOVIMIENTOS_PRESUPUESTALES(id_traslado_asociado);


CREATE INDEX idx_traslados_origen ON TRASLADOS_PRESUPUESTALES(id_presupuesto_origen);
CREATE INDEX idx_traslados_destino ON TRASLADOS_PRESUPUESTALES(id_presupuesto_destino);
CREATE INDEX idx_traslados_estado ON TRASLADOS_PRESUPUESTALES(estado_traslado);
CREATE INDEX idx_traslados_fecha_solicitud ON TRASLADOS_PRESUPUESTALES(fecha_solicitud);
