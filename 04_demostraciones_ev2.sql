-- 04_demostraciones_ev2.sql | ROLLY | BDY1103 | Oracle 12c+
SET SERVEROUTPUT ON;
PROMPT A. FUNCIONES CON Y SIN PARAMETROS DESDE SQL
SELECT fn_calcular_inversion_reposicion(12,20,19990) inversion_reposicion FROM dual;
SELECT fn_valorizacion_total_bodega() valorizacion_bodega FROM dual;
SELECT pkg_gestion_rolly.fn_obtener_valor_producto(1) valor_producto_1 FROM dual;

PROMPT B. FUNCIONES DESDE PL/SQL
DECLARE v_inversion NUMBER; v_bodega NUMBER;
BEGIN
 v_inversion:=fn_calcular_inversion_reposicion(12,20,19990);
 v_bodega:=fn_valorizacion_total_bodega();
 DBMS_OUTPUT.PUT_LINE('Inversion estimada: $'||v_inversion);
 DBMS_OUTPUT.PUT_LINE('Valorizacion bodega: $'||v_bodega);
END;
/

PROMPT C. PROCEDIMIENTO SIN PARAMETROS: PROCESAMIENTO MASIVO
BEGIN sp_generar_alertas_masivas(); END;
/

PROMPT D. PROCEDIMIENTO CON PARAMETROS
-- Categoria inexistente para demostrar la invocacion sin cambiar el catalogo.
BEGIN sp_reajustar_precios_categoria('__CATEGORIA_DE_PRUEBA__',5); END;
/

PROMPT E. PACKAGE: PROCEDIMIENTO Y FUNCION PUBLICOS
BEGIN
 pkg_gestion_rolly.sp_aplicar_descuento_categoria('__CATEGORIA_DE_PRUEBA__',5);
END;
/
DECLARE v_valor NUMBER;
BEGIN
 v_valor:=pkg_gestion_rolly.fn_obtener_valor_producto(1);
 DBMS_OUTPUT.PUT_LINE('Valor producto 1: $'||v_valor);
END;
/

PROMPT F. TRIGGERS DE FILA Y SENTENCIA
-- Actualiza a su mismo valor: dispara ambos triggers sin alterar el stock.
UPDATE producto SET stock=stock WHERE id_producto=1;
COMMIT;
SELECT id_bitacora,tabla_afectada,tipo_operacion,nivel_trigger,detalle_evento,
       usuario_bd,fecha_evento
FROM bitacora_auditoria ORDER BY id_bitacora DESC;

PROMPT G. ALERTAS Y REGLAS DE NEGOCIO
SELECT id_producto,nombre_producto,stock_detectado,cantidad_sugerida,
       inversion_estimada,nivel_urgencia
FROM alertas_reposicion ORDER BY stock_detectado,nombre_producto;
SELECT COUNT(*) total_productos,MIN(precio) precio_minimo,MAX(precio) precio_maximo,
       MIN(stock) stock_minimo,MAX(stock) stock_maximo FROM producto;

-- Pruebas negativas opcionales: descomentar para validar rechazo del trigger.
-- UPDATE producto SET stock=9 WHERE id_producto=1;      -- ORA-20001 esperado
-- UPDATE producto SET precio=14000 WHERE id_producto=1; -- ORA-20002 esperado
