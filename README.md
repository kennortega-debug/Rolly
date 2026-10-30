# 👟 Sistema de Gestión y Auditoría de Inventario - ROLLY

Proyecto académico de base de datos para una tienda dedicada a la venta de zapatillas. La solución administra productos, ventas, detalle de ventas, movimientos de inventario, alertas de reposición y auditoría mediante Oracle PL/SQL.

## 🎯 Objetivo del proyecto

Implementar una base de datos relacional para ROLLY que permita mantener un catálogo de zapatillas, controlar existencias y precios, registrar ventas y movimientos de inventario, detectar productos que requieren reposición y auditar cambios realizados sobre el catálogo.

## 🛠️ Tecnologías

- **Motor de base de datos:** Oracle Database 12c o superior.
- **Lenguaje:** SQL y PL/SQL.
- **Herramienta recomendada:** Oracle SQL Developer.
- **Moneda:** pesos chilenos (CLP).

## 📏 Reglas de negocio

- Cada producto tiene un identificador único (primary key).
- Los productos corresponden a zapatillas.
- El precio debe estar entre **$15.000 y $32.000**.
- El stock debe estar entre **10 y 100 unidades**.
- La talla debe estar entre 20 y 50.
- Los descuentos no pueden dejar el precio bajo $15.000.
- Una salida de inventario que deje menos de 10 unidades debe rechazarse o gestionarse mediante reposición.

## 📂 Estructura del repositorio

| Archivo | Descripción |
|---|---|
| `01_tablas_rolly.sql` | Limpieza controlada, creación de tablas, relaciones, índices y carga inicial de 10 modelos de zapatillas. |
| `02_bloque_plsql.sql` | Bloque anónimo con RECORD, VARRAY, cursores explícitos, ciclos y manejo de excepciones para detectar stock crítico. |
| `03_objetos_plsql_ev2.sql` | Funciones, procedimientos almacenados, PACKAGE público/privado, triggers de fila y sentencia y pruebas integrales. |

## 🧩 Objetos PL/SQL incluidos

- **Funciones:** `fn_calcular_inversion_reposicion` calcula el monto sugerido para reponer; `fn_valorizacion_total_bodega` calcula el valor del inventario.
- **Procedimientos:** `sp_generar_alertas_masivas` genera alertas; `sp_reajustar_precios_categoria` permite reajustar precios dentro de las reglas.
- **Package:** `pkg_gestion_rolly` agrupa funciones y procedimientos públicos e incluye una función privada para validar el precio con descuento.
- **Triggers:** `trg_auditoria_fila_producto` valida y audita cambios por fila; `trg_auditoria_sentencia_producto` registra operaciones DML a nivel de sentencia.

## ▶️ Orden de ejecución

Ejecutar los scripts en este orden desde Oracle SQL Developer, conectado al esquema que utilizará el proyecto:

1. Abrir `01_tablas_rolly.sql` y ejecutar con **F5 (Run Script)**.
2. Abrir `02_bloque_plsql.sql` y ejecutar con **F5**.
3. Abrir `03_objetos_plsql_ev2.sql` y ejecutar con **F5**.
4. Revisar los resultados en DBMS Output y las consultas de verificación.

> **Importante:** el primer script elimina y vuelve a crear las tablas indicadas si ya existen. Ejecutarlo nuevamente borra los datos de esas tablas. La creación de los archivos en GitHub no ejecuta la base de datos; los scripts deben correrse en Oracle.

## 🔎 Verificación

Al finalizar, consultar `PRODUCTO`, `ALERTAS_REPOSICION` y `BITACORA_AUDITORIA` para revisar los datos, las alertas y los registros de auditoría.
