-- =====================================================================================
-- PROYECTO: Red Social Estudiantil Pascualina
-- ENTREGABLE FINAL: Script DML (Vistas Analíticas y Consultas SQL)
-- MOTOR DBMS: SQL Server (T-SQL)
-- =====================================================================================

USE RedSocialPascualina;
GO

-- =====================================================================================
-- PARTE 1: CREACIÓN DE VISTAS ANALÍTICAS (MODELOS DE CONSULTA)
-- =====================================================================================

-- -------------------------------------------------------------------------------------
-- VISTA 1: Analítica de Eventos y Telemetría IoT
-- Objetivo: Relacionar la asistencia a eventos con los datos de telemetría capturados.
-- Justificación de Alias: Se usan prefijos descriptivos y el sufijo '_json' para indicar el formato.
-- -------------------------------------------------------------------------------------
CREATE OR ALTER VIEW vw_analitica_eventos_iot AS
SELECT 
    ev.titulo_evento AS nombre_del_evento, 
    ev.lugar AS ubicacion_evento,
    est.nombre_completo AS estudiante_asistente,
    est.programa_academico AS carrera_estudiante,
    ae.registro_iot AS datos_telemetria_json -- Formato JSON extraído de los sensores
FROM 
    evento ev
INNER JOIN 
    asistente_evento ae ON ev.id_evento = ae.id_evento
INNER JOIN 
    estudiante est ON ae.id_estudiante = est.id_estudiante;
GO

-- -------------------------------------------------------------------------------------
-- VISTA 2: Creadores de Contenido y Engagement
-- Objetivo: Medir la participación de los estudiantes en la plataforma.
-- Justificación de Alias: Prefijos matemáticos (total_, fecha_ultima_) para indicar agregación.
-- -------------------------------------------------------------------------------------
CREATE OR ALTER VIEW vw_creadores_contenido_activos AS
SELECT 
    est.id_estudiante,
    est.nombre_completo AS autor_contenido,
    est.correo_institucional AS contacto,
    COUNT(pub.id_publicacion) AS total_publicaciones_realizadas, 
    MAX(pub.fecha_creacion) AS fecha_ultima_publicacion
FROM 
    estudiante est
LEFT JOIN 
    publicacion pub ON est.id_estudiante = pub.id_autor
GROUP BY 
    est.id_estudiante, 
    est.nombre_completo, 
    est.correo_institucional;
GO

-- -------------------------------------------------------------------------------------
-- VISTA 3: Demografía y Liderazgo en Grupos de Estudio
-- Objetivo: Identificar el nivel de adopción de las comunidades y sus líderes.
-- Justificación de Alias: Subconsulta con alias claro de métrica (cantidad_total_miembros).
-- -------------------------------------------------------------------------------------
CREATE OR ALTER VIEW vw_demografia_grupos_estudio AS
SELECT 
    g.nombre_grupo AS comunidad_academica,
    g.fecha_creacion AS fecha_lanzamiento_grupo,
    est.nombre_completo AS administrador_principal,
    (
        SELECT COUNT(id_estudiante) 
        FROM miembro_grupo mg_sub 
        WHERE mg_sub.id_grupo = g.id_grupo
    ) AS cantidad_total_miembros 
FROM 
    grupo g
INNER JOIN 
    miembro_grupo mg ON g.id_grupo = mg.id_grupo
INNER JOIN 
    estudiante est ON mg.id_estudiante = est.id_estudiante
WHERE 
    mg.rol_miembro = 'admin';
GO


-- =====================================================================================
-- PARTE 2: EXPLOTACIÓN DE DATOS (CONSULTAS DML SOBRE LAS VISTAS)
-- =====================================================================================

-- Consulta a Vista 1: Analizar asistencia a eventos específicos
SELECT * 
FROM vw_analitica_eventos_iot
ORDER BY nombre_del_evento ASC;
GO

-- Consulta a Vista 2: Top de Influencers Académicos (Filtro por alta participación)
SELECT 
    autor_contenido,
    total_publicaciones_realizadas,
    fecha_ultima_publicacion
FROM 
    vw_creadores_contenido_activos
WHERE 
    total_publicaciones_realizadas > 5
ORDER BY 
    total_publicaciones_realizadas DESC;
GO

-- Consulta a Vista 3: Comunidades Consolidadas (Filtro por volumen de miembros)
SELECT 
    comunidad_academica,
    administrador_principal,
    cantidad_total_miembros
FROM 
    vw_demografia_grupos_estudio
WHERE 
    cantidad_total_miembros >= 10
ORDER BY 
    cantidad_total_miembros DESC;
GO


-- =====================================================================================
-- PARTE 3: CONSULTAS DML AVANZADAS (Reglas de Negocio Específicas)
-- =====================================================================================

-- Consulta de Diferencia (EXCEPT): Estudiantes inactivos que NUNCA han publicado
SELECT correo_institucional FROM estudiante
EXCEPT
SELECT est.correo_institucional 
FROM estudiante est
INNER JOIN publicacion pub ON est.id_estudiante = pub.id_autor;
GO

-- Consulta con Subconsulta Escalar en el HAVING: Estudiantes sobre el promedio global
SELECT 
    id_autor, 
    COUNT(id_publicacion) AS cantidad_publicaciones 
FROM 
    publicacion
GROUP BY 
    id_autor
HAVING 
    COUNT(id_publicacion) > (
        -- Subconsulta que calcula el promedio exacto a nivel global
        SELECT CAST(COUNT(id_publicacion) AS DECIMAL(10,2)) / NULLIF(COUNT(DISTINCT id_autor), 0)
        FROM publicacion
    );
GO
