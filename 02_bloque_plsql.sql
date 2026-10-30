-- =========================================================================
-- ARCHIVO: 02_bloque_plsql.sql
-- PROYECTO: Sistema de Gestión y Auditoría - Tienda ROLLY
-- CONTENIDO: RECORD, VARRAY, cursores, ciclos y excepciones
-- =========================================================================

SET SERVEROUTPUT ON;

DECLARE
    TYPE t_info_producto IS RECORD (
        id_producto NUMBER,
        nombre_producto VARCHAR2(100),
        stock_actual NUMBER
    );

    TYPE t_arreglo_alertas IS VARRAY(20) OF t_info_producto;
    v_alertas t_arreglo_alertas := t_arreglo_alertas();

    CURSOR c_categorias IS
        SELECT DISTINCT categoria
        FROM producto
        ORDER BY categoria;

    CURSOR c_productos (p_categoria VARCHAR2, p_stock_min NUMBER) IS
        SELECT id_producto, nombre, stock
        FROM producto
        WHERE categoria = p_categoria
          AND stock <= p_stock_min
        ORDER BY stock ASC;

    e_stock_critico EXCEPTION;
    v_idx NUMBER := 0;
    v_total_criticos NUMBER := 0;
BEGIN
    v_alertas.EXTEND(20);

    FOR v_cat IN c_categorias LOOP
        DBMS_OUTPUT.PUT_LINE('--- Categoría: ' || v_cat.categoria || ' ---');

        FOR v_prod IN c_productos(v_cat.categoria, 20) LOOP
            v_total_criticos := v_total_criticos + 1;

            IF v_idx < 20 THEN
                v_idx := v_idx + 1;
                v_alertas(v_idx).id_producto := v_prod.id_producto;
                v_alertas(v_idx).nombre_producto := v_prod.nombre;
                v_alertas(v_idx).stock_actual := v_prod.stock;
            END IF;

            BEGIN
                IF v_prod.stock <= 15 THEN
                    RAISE e_stock_critico;
                END IF;

                DBMS_OUTPUT.PUT_LINE('Stock preventivo: ' || v_prod.nombre ||
                                     ' - unidades: ' || v_prod.stock);
            EXCEPTION
                WHEN e_stock_critico THEN
                    DBMS_OUTPUT.PUT_LINE('ALERTA: revisar reposición de ' ||
                                         v_prod.nombre || ' (stock ' || v_prod.stock || ')');
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Error al revisar producto: ' || SQLERRM);
            END;
        END LOOP;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Productos detectados bajo umbral: ' || v_total_criticos);
    DBMS_OUTPUT.PUT_LINE('Productos almacenados en VARRAY: ' || v_idx);

    FOR i IN 1..v_idx LOOP
        DBMS_OUTPUT.PUT_LINE(v_alertas(i).id_producto || ' - ' ||
                             v_alertas(i).nombre_producto || ' - stock: ' ||
                             v_alertas(i).stock_actual);
    END LOOP;
END;
/
