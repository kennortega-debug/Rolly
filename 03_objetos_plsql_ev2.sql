-- =========================================================================
-- ARCHIVO: 03_objetos_plsql_ev2.sql
-- PROYECTO: Sistema de Gestión y Auditoría - Tienda ROLLY
-- CONTENIDO: Funciones, procedimientos, package y triggers
-- =========================================================================

SET SERVEROUTPUT ON;

-- 1. FUNCIONES ALMACENADAS

-- Calcula el valor de reposición para llevar el producto al stock objetivo.
CREATE OR REPLACE FUNCTION fn_calcular_inversion_reposicion (
    p_stock_actual IN NUMBER,
    p_stock_objetivo IN NUMBER,
    p_precio IN NUMBER
) RETURN NUMBER IS
    v_unidades NUMBER := 0;
BEGIN
    IF p_stock_actual < p_stock_objetivo THEN
        v_unidades := p_stock_objetivo - p_stock_actual;
    END IF;
    RETURN v_unidades * p_precio;
END fn_calcular_inversion_reposicion;
/

-- Calcula la valorización total del inventario a precio de venta.
CREATE OR REPLACE FUNCTION fn_valorizacion_total_bodega
RETURN NUMBER IS
    v_total NUMBER := 0;
BEGIN
    SELECT NVL(SUM(stock * precio), 0)
    INTO v_total
    FROM producto;
    RETURN v_total;
END fn_valorizacion_total_bodega;
/

-- 2. PROCEDIMIENTOS ALMACENADOS

-- Genera alertas de reposición para productos con stock igual o inferior a 20.
CREATE OR REPLACE PROCEDURE sp_generar_alertas_masivas IS
    CURSOR c_criticos IS
        SELECT id_producto, nombre, stock, stock_minimo, precio
        FROM producto
        WHERE stock <= 20
        ORDER BY stock ASC;

    v_inversion NUMBER;
    v_urgencia VARCHAR2(30);
    v_contador NUMBER := 0;
BEGIN
    DELETE FROM alertas_reposicion;

    FOR r IN c_criticos LOOP
        v_inversion := fn_calcular_inversion_reposicion(
            r.stock, r.stock_minimo * 2, r.precio
        );

        IF r.stock <= 15 THEN
            v_urgencia := 'ALTA - STOCK CRITICO';
        ELSE
            v_urgencia := 'MEDIA - PREVENTIVA';
        END IF;

        INSERT INTO alertas_reposicion (
            id_producto, nombre_producto, stock_detectado,
            cantidad_sugerida, inversion_estimada, nivel_urgencia
        ) VALUES (
            r.id_producto, r.nombre, r.stock,
            GREATEST((r.stock_minimo * 2) - r.stock, 0),
            v_inversion, v_urgencia
        );
        v_contador := v_contador + 1;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Alertas de reposición generadas: ' || v_contador);
END sp_generar_alertas_masivas;
/

-- Ajusta precios de una categoría sin salir del rango comercial permitido.
CREATE OR REPLACE PROCEDURE sp_reajustar_precios_categoria (
    p_categoria IN VARCHAR2,
    p_porcentaje IN NUMBER
) IS
    v_filas NUMBER;
BEGIN
    IF p_porcentaje IS NULL OR p_porcentaje < -50 OR p_porcentaje > 50 THEN
        RAISE_APPLICATION_ERROR(-20010, 'El porcentaje debe estar entre -50 y 50.');
    END IF;

    UPDATE producto
    SET precio = ROUND(precio * (1 + p_porcentaje / 100))
    WHERE categoria = p_categoria
      AND ROUND(precio * (1 + p_porcentaje / 100)) BETWEEN 15000 AND 32000;

    v_filas := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Productos reajustados: ' || v_filas);
END sp_reajustar_precios_categoria;
/

-- 3. PACKAGE: interfaz pública e implementación privada
CREATE OR REPLACE PACKAGE pkg_gestion_rolly IS
    c_stock_objetivo CONSTANT NUMBER := 20;
    FUNCTION fn_obtener_valor_producto(p_id_producto IN NUMBER) RETURN NUMBER;
    PROCEDURE sp_aplicar_descuento_categoria(
        p_categoria IN VARCHAR2,
        p_descuento_pct IN NUMBER
    );
END pkg_gestion_rolly;
/

CREATE OR REPLACE PACKAGE BODY pkg_gestion_rolly IS
    -- Función privada: valida que el descuento respete el precio mínimo.
    FUNCTION fn_precio_es_valido_priv(p_precio NUMBER) RETURN BOOLEAN IS
    BEGIN
        RETURN p_precio BETWEEN 15000 AND 32000;
    END fn_precio_es_valido_priv;

    FUNCTION fn_obtener_valor_producto(p_id_producto IN NUMBER) RETURN NUMBER IS
        v_valor NUMBER;
    BEGIN
        SELECT precio * stock
        INTO v_valor
        FROM producto
        WHERE id_producto = p_id_producto;
        RETURN v_valor;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END fn_obtener_valor_producto;

    PROCEDURE sp_aplicar_descuento_categoria(
        p_categoria IN VARCHAR2,
        p_descuento_pct IN NUMBER
    ) IS
        CURSOR c_productos IS
            SELECT id_producto, precio
            FROM producto
            WHERE categoria = p_categoria;
        v_nuevo_precio NUMBER;
        v_aplicados NUMBER := 0;
        v_bloqueados NUMBER := 0;
    BEGIN
        IF p_descuento_pct IS NULL OR p_descuento_pct < 0 OR p_descuento_pct > 50 THEN
            RAISE_APPLICATION_ERROR(-20011, 'Descuento permitido: entre 0 y 50%.');
        END IF;

        FOR r IN c_productos LOOP
            v_nuevo_precio := ROUND(r.precio * (1 - p_descuento_pct / 100));
            IF fn_precio_es_valido_priv(v_nuevo_precio) THEN
                UPDATE producto
                SET precio = v_nuevo_precio
                WHERE id_producto = r.id_producto;
                v_aplicados := v_aplicados + 1;
            ELSE
                v_bloqueados := v_bloqueados + 1;
            END IF;
        END LOOP;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Descuentos aplicados: ' || v_aplicados ||
                             ' | Bloqueados por precio mínimo: ' || v_bloqueados);
    END sp_aplicar_descuento_categoria;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Package PKG_GESTION_ROLLY inicializado.');
END pkg_gestion_rolly;
/

-- 4. TRIGGERS DE AUDITORÍA

-- Trigger a nivel de fila: valida precio/stock y registra cambios.
CREATE OR REPLACE TRIGGER trg_auditoria_fila_producto
BEFORE INSERT OR UPDATE OF stock, precio ON producto
FOR EACH ROW
BEGIN
    IF :NEW.stock NOT BETWEEN 10 AND 100 THEN
        RAISE_APPLICATION_ERROR(-20001, 'El stock debe estar entre 10 y 100 unidades.');
    END IF;

    IF :NEW.precio NOT BETWEEN 15000 AND 32000 THEN
        RAISE_APPLICATION_ERROR(-20002, 'El precio debe estar entre $15.000 y $32.000.');
    END IF;

    IF UPDATING THEN
        INSERT INTO bitacora_auditoria (
            tabla_afectada, tipo_operacion, nivel_trigger, detalle_evento
        ) VALUES (
            'PRODUCTO', 'UPDATE', 'FILA',
            'Producto ' || :OLD.id_producto ||
            ': stock ' || :OLD.stock || ' -> ' || :NEW.stock ||
            '; precio ' || :OLD.precio || ' -> ' || :NEW.precio
        );
    END IF;
END trg_auditoria_fila_producto;
/

-- Trigger a nivel de sentencia: registra cada operación DML global.
CREATE OR REPLACE TRIGGER trg_auditoria_sentencia_producto
AFTER INSERT OR UPDATE OR DELETE ON producto
DECLARE
    v_operacion VARCHAR2(20);
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERT';
    ELSIF UPDATING THEN
        v_operacion := 'UPDATE';
    ELSE
        v_operacion := 'DELETE';
    END IF;

    INSERT INTO bitacora_auditoria (
        tabla_afectada, tipo_operacion, nivel_trigger, detalle_evento
    ) VALUES (
        'PRODUCTO', v_operacion, 'SENTENCIA',
        'Operación DML sobre PRODUCTO ejecutada por ' || USER
    );
END trg_auditoria_sentencia_producto;
/

-- 5. PRUEBAS DE FUNCIONAMIENTO
BEGIN
    DBMS_OUTPUT.PUT_LINE('Valor total del inventario: $' ||
                         fn_valorizacion_total_bodega());

    sp_generar_alertas_masivas();

    DBMS_OUTPUT.PUT_LINE('Valor del producto 1: $' ||
                         pkg_gestion_rolly.fn_obtener_valor_producto(1));

    -- Prueba de auditoría (actualización controlada dentro de rango).
    UPDATE producto
    SET stock = stock
    WHERE id_producto = 1;
    COMMIT;
END;
/

-- Consultas de verificación
SELECT * FROM alertas_reposicion ORDER BY nivel_urgencia, stock_detectado;
SELECT * FROM bitacora_auditoria ORDER BY id_bitacora DESC;
