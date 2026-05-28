-- 1. LIMPIEZA E INICIO
DROP DATABASE IF EXISTS justicia_genero_mex;
CREATE DATABASE justicia_genero_mex;
USE justicia_genero_mex;

-- 2. TABLAS
CREATE TABLE dim_municipio (
    municipio_id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100),
    estado VARCHAR(50),
    alerta_genero BOOLEAN
);

CREATE TABLE dim_victima (
    victima_id INT PRIMARY KEY AUTO_INCREMENT,
    curp VARCHAR(18) UNIQUE,
    nombre_anonimo VARCHAR(150),
    edad_rango VARCHAR(50)
);

CREATE TABLE dim_agresor (
    agresor_id INT PRIMARY KEY AUTO_INCREMENT,
    perfil_psicologico TEXT,
    estatus_legal VARCHAR(50)
);

CREATE TABLE hecho_feminicidio (
    caso_id INT PRIMARY KEY AUTO_INCREMENT,
    folio_fiscalia VARCHAR(50) UNIQUE,
    municipio_id INT,
    victima_id INT,
    agresor_id INT,
    fecha_hecho DATE,
    medio_comision VARCHAR(100),
    lugar_hallazgo VARCHAR(100),
    sentencia_anios INT,
    FOREIGN KEY (municipio_id) REFERENCES dim_municipio(municipio_id),
    FOREIGN KEY (victima_id) REFERENCES dim_victima(victima_id),
    FOREIGN KEY (agresor_id) REFERENCES dim_agresor(agresor_id)
);

-- 3. VISTA 
CREATE OR REPLACE VIEW vw_termometro_impunidad AS
SELECT 
    f.folio_fiscalia,
    m.nombre AS municipio,
    f.medio_comision,
    f.sentencia_anios,
    CASE 
        WHEN f.sentencia_anios = 0 THEN 'Sin sentencia'
        ELSE 'Con sentencia'
    END AS diagnostico_justicia
FROM hecho_feminicidio f
JOIN dim_municipio m ON f.municipio_id = m.municipio_id;

-- 4. PROCEDIMIENTOS 
DELIMITER $$

CREATE PROCEDURE sp_upsert_caso(
    IN p_folio VARCHAR(50), IN p_muni_id INT, IN p_vic_id INT, 
    IN p_agr_id INT, IN p_fecha DATE, IN p_medio VARCHAR(100), 
    IN p_lugar VARCHAR(100), IN p_sentencia INT
)
BEGIN
    INSERT INTO hecho_feminicidio (folio_fiscalia, municipio_id, victima_id, agresor_id, fecha_hecho, medio_comision, lugar_hallazgo, sentencia_anios)
    VALUES (p_folio, p_muni_id, p_vic_id, p_agr_id, p_fecha, p_medio, p_lugar, p_sentencia)
    ON DUPLICATE KEY UPDATE sentencia_anios = p_sentencia;
END $$

CREATE PROCEDURE sp_get_data_for_nosql()
BEGIN
    SELECT * FROM vw_termometro_impunidad;
END $$

DELIMITER ;

-- 5. SEMBRADO DE DATOS 
INSERT INTO dim_municipio (nombre, estado, alerta_genero) VALUES ('Ecatepec', 'Edomex', 1);
INSERT INTO dim_victima (curp, nombre_anonimo, edad_rango) VALUES ('VIVA900101HDFLRS0', 'Maria N.', '30-44');
INSERT INTO dim_agresor (perfil_psicologico, estatus_legal) VALUES ('Sin antecedentes', 'Detenido');

-- 6.EL CALL
CALL sp_upsert_caso('FOLIO-2025-001', 1, 1, 1, '2025-05-20', 'Arma blanca', 'Vivienda', 50);
