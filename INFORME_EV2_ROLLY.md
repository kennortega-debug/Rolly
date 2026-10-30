# Informe técnico – Evaluación Parcial 2 | ROLLY

**Asignatura:** BDY1103 – Taller de Base de Datos  
**Motor:** Oracle Database 12c o superior  
**Repositorio:** https://github.com/kennortega-debug/Rolly

## Resumen ejecutivo
ROLLY es una tienda de zapatillas. Esta solución PL/SQL administra catálogo, ventas, inventario, alertas de reposición y auditoría. Integra procedimientos y funciones con/sin parámetros, un package con miembros públicos y rutina privada, y triggers a nivel de fila y sentencia.

## 1. Introducción
### Descripción y problema
La gestión dispersa de precios y existencias puede provocar diferencias entre inventario registrado y disponible, reposiciones tardías y falta de evidencia de cambios. ROLLY centraliza reglas y procesos en Oracle. Los objetos PL/SQL automatizan cálculos, procesamiento masivo, validaciones y trazabilidad.

### Alcance
Incluye catálogo, ventas, detalle de ventas, movimientos de inventario, alertas y bitácora. Reglas: precio entre $15.000 y $32.000 CLP; stock entre 10 y 100 unidades; talla entre 20 y 50. No incluye pagos, facturación electrónica ni integración externa con proveedores.

### Datos, información y tecnologías
Datos: ID, nombre, marca, modelo, talla, color, categoría, precio, stock, fechas y estados de ventas, cantidades, movimientos y auditoría. Información: valorización de bodega, inversión de reposición, alertas, cantidad sugerida y trazabilidad. Tecnologías: Oracle Database 12c+, SQL, PL/SQL, Oracle SQL Developer y GitHub.

## 2. Procedimientos y funciones
### Procedimientos: definición y características
Un procedimiento almacenado es una unidad PL/SQL con nombre que ejecuta una tarea y puede recibir parámetros IN, OUT o IN OUT. Puede incluir consultas, cursores, DML y manejo de excepciones.

### Procedimientos implementados y demostración
- `SP_GENERAR_ALERTAS_MASIVAS` no recibe parámetros. Recorre con un cursor los productos con stock ≤20, calcula inversión para alcanzar el objetivo y registra alertas con urgencia.
- `SP_REAJUSTAR_PRECIOS_CATEGORIA` recibe categoría y porcentaje. Valida el porcentaje (-50% a 50%) y actualiza solo precios cuyo resultado quede entre $15.000 y $32.000.
- El package incluye `SP_APLICAR_DESCUENTO_CATEGORIA`.

Ejemplos: `BEGIN SP_GENERAR_ALERTAS_MASIVAS(); END;` y `BEGIN SP_REAJUSTAR_PRECIOS_CATEGORIA('Urbana',5); END;`. En el archivo de demostraciones se usa una categoría inexistente para no modificar el catálogo durante esa prueba.

### Ventajas y desventajas de procedimientos
Ventajas: reutilización, centralización, procesamiento masivo y menor duplicación. Desventajas: dependencia del motor, despliegue/versionado y depuración especializada. Los COMMIT internos simplifican la demostración; en producción conviene controlar la transacción desde el proceso coordinador.

### Funciones: definición, implementación y demostración
Una función almacenada devuelve un valor mediante RETURN. `FN_CALCULAR_INVERSION_REPOSICION(actual, objetivo, precio)` estima el costo de unidades faltantes; `FN_VALORIZACION_TOTAL_BODEGA()` devuelve SUM(stock*precio); `PKG_GESTION_ROLLY.FN_OBTENER_VALOR_PRODUCTO(id)` devuelve el valor de inventario de un producto.

Ejemplos SQL: `SELECT FN_CALCULAR_INVERSION_REPOSICION(12,20,19990) FROM DUAL;` y `SELECT FN_VALORIZACION_TOTAL_BODEGA() FROM DUAL;`. También pueden asignarse a variables desde PL/SQL.

Ventajas: encapsulan cálculos, estandarizan resultados y se reutilizan desde SQL/PLSQL. Desventajas: consultas costosas dentro de funciones pueden repetirse; las funciones invocadas desde SQL tienen restricciones sobre efectos secundarios.

## 3. Packages
### Definición y estructura
Un package agrupa tipos, constantes, variables, procedimientos y funciones. La especificación declara la interfaz pública; el cuerpo implementa los miembros y puede contener subprogramas privados.

### PKG_GESTION_ROLLY
Expone `C_STOCK_OBJETIVO`, `FN_OBTENER_VALOR_PRODUCTO` y `SP_APLICAR_DESCUENTO_CATEGORIA`. El cuerpo contiene `FN_PRECIO_ES_VALIDO_PRIV`, función privada que valida el rango comercial y solo es visible internamente.

### Organización, relación, demostración y ventajas/desventajas
El package ofrece un punto de acceso coherente. El procedimiento público coordina descuentos por categoría y reutiliza la función privada; la función pública entrega valorización individual. Ejemplo: `SELECT PKG_GESTION_ROLLY.FN_OBTENER_VALOR_PRODUCTO(1) FROM DUAL;`. Ventajas: modularidad, encapsulamiento, cohesión e interfaz estable. Desventajas: mayor estructura inicial y dependencia entre especificación, cuerpo y consumidores. La pauta dice “constructores públicos y privados”; en PL/SQL se evidencia mediante miembros públicos declarados en la especificación y una rutina privada definida solo en el cuerpo.

## 4. Triggers
### Definición y características
Un trigger es un bloque PL/SQL ejecutado automáticamente ante eventos sobre una tabla. Puede ser BEFORE/AFTER y por fila (`FOR EACH ROW`) o por sentencia. Los triggers por fila acceden a `:OLD` y `:NEW`.

### Trigger de fila
`TRG_AUDITORIA_FILA_PRODUCTO` se ejecuta BEFORE INSERT o UPDATE de stock/precio por cada fila. Valida stock 10–100 y precio $15.000–$32.000; en UPDATE registra valores anteriores y nuevos. Si falla la regla, cancela con `RAISE_APPLICATION_ERROR`.

### Trigger de sentencia
`TRG_AUDITORIA_SENTENCIA_PRODUCTO` se ejecuta AFTER INSERT/UPDATE/DELETE una vez por sentencia y registra la operación general en `BITACORA_AUDITORIA`.

### Demostración, ventajas y desventajas
`UPDATE PRODUCTO SET STOCK=STOCK WHERE ID_PRODUCTO=1;` dispara ambos triggers sin cambiar el stock. Luego se consulta `BITACORA_AUDITORIA` para observar niveles FILA y SENTENCIA. Ventajas: reglas automáticas y trazabilidad central. Desventajas: lógica menos visible, riesgo de duplicación, impacto en rendimiento y depuración más compleja.

## 5. Integración y flujo
PRODUCTO conserva el catálogo; los procedimientos recorren productos y generan alertas; las funciones calculan inversión y valorización; `PKG_GESTION_ROLLY` agrupa operaciones de categoría; los triggers validan y auditan DML. PRODUCTO se relaciona con VENTA/DETALLE_VENTA; MOVIMIENTOS_INVENTARIO registra entradas, salidas y ajustes; ALERTAS_REPOSICION conserva alertas; BITACORA_AUDITORIA registra eventos.

## 6. Conclusión
La solución integra procedimientos y funciones con/sin parámetros, package público/privado y triggers de fila/sentencia. El impacto esperado es mejorar consistencia de stock/precios, oportunidad de reposición, indicadores de inventario y trazabilidad.

### Recomendaciones
Ejecutar y validar en Oracle 12c+; revisar USER_ERRORS; agregar pruebas automatizadas de ventas, anulaciones y concurrencia; separar COMMIT/ROLLBACK de la lógica; incorporar roles, proveedores e informes por período.

## 7. Anexos
Código completo: `01_tablas_rolly.sql`, `02_bloque_plsql.sql`, `03_objetos_plsql_ev2.sql`, `04_demostraciones_ev2.sql`. Ejecutar con F5 en ese orden. El primer script elimina y recrea tablas, por lo que debe usarse solo en un esquema de pruebas.

**Estado de validación:** material revisado estáticamente. No se afirma ejecución/compilación real en Oracle; la validación final debe realizarse en SQL Developer y registrar DBMS_OUTPUT, consultas de auditoría y estado de objetos.
