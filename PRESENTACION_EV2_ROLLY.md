# Presentación ejecutiva – Evaluación Parcial 2 | ROLLY

## 1. ROLLY
Evaluación Parcial 2 · BDY1103. Sistema de Gestión y Auditoría de Inventario.

## 2. El problema del negocio
- Precios y stock deben respetar reglas comerciales.
- El stock crítico exige reposición oportuna.
- Los cambios deben quedar trazables.
- Riesgo: errores de inventario y decisiones tardías.

## 3. Objetivo y alcance
- Catálogo, ventas y detalle de ventas.
- Movimientos y alertas de reposición.
- Auditoría de cambios del catálogo.
- Precio $15.000–$32.000 CLP; stock 10–100; talla 20–50.

## 4. Datos e información generada
- ID, modelo, talla, categoría, precio y stock.
- Valorización de bodega e inversión de reposición.
- Stock detectado, cantidad sugerida y urgencia.
- Operación, nivel de trigger, usuario y fecha.

## 5. Procedimientos: procesamiento masivo
- SP_GENERAR_ALERTAS_MASIVAS() — sin parámetros.
- Recorre productos con stock ≤20 y genera alertas.
- SP_REAJUSTAR_PRECIOS_CATEGORIA(categoría, %) — con parámetros.
- Valida porcentaje y rango final de precios.

## 6. Funciones: indicadores reutilizables
- FN_CALCULAR_INVERSION_REPOSICION(actual, objetivo, precio).
- FN_VALORIZACION_TOTAL_BODEGA().
- SQL: SELECT FN_VALORIZACION_TOTAL_BODEGA() FROM DUAL.
- Permiten estimar reposición y valor del inventario.

## 7. Package: público y privado
- PKG_GESTION_ROLLY agrupa operaciones relacionadas.
- Públicos: FN_OBTENER_VALOR_PRODUCTO y SP_APLICAR_DESCUENTO_CATEGORIA.
- Constante pública: C_STOCK_OBJETIVO.
- Privado: FN_PRECIO_ES_VALIDO_PRIV.

## 8. Triggers: control automático
- Fila: TRG_AUDITORIA_FILA_PRODUCTO.
- Valida stock 10–100 y precio $15.000–$32.000.
- Registra valores anteriores/nuevos.
- Sentencia: TRG_AUDITORIA_SENTENCIA_PRODUCTO registra INSERT/UPDATE/DELETE.

## 9. Flujo integrado
- Catálogo → procedimientos procesan stock.
- Funciones → calculan inversión y valorización.
- Package → coordina operaciones de categoría.
- Triggers → validan reglas y registran auditoría.

## 10. Conclusión y próximos pasos
- PL/SQL centraliza reglas y procesamiento masivo.
- Alertas e indicadores apoyan decisiones de inventario.
- Auditoría distingue cambios por fila y por sentencia.
- Próximo paso: ejecutar y validar scripts en Oracle 12c+.

## Cierre sugerido
La solución integra procedimientos, funciones, package y triggers para centralizar reglas de negocio, generar indicadores de reposición y valorización, y auditar cambios. El siguiente paso es ejecutar y validar los scripts en Oracle SQL Developer.
