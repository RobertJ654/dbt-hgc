{{ config(materialized='table') }}
with pedidos as (select * from {{ ref('stg_postgres__pedidos') }}),
     detalle as (select * from {{ ref('stg_postgres__detalle_pedido') }})

select
    -- 1. Claves Foráneas
    cast(to_char(p.fecha_hora_transaccion, 'YYYYMMDD') as integer) as id_fecha_sk,
    cast(to_char(p.fecha_hora_transaccion, 'HH24MI') as integer) as id_hora_sk,
    ds.id_sucursal_sk,
    dp.id_producto_sk,
    dc.id_cliente_sk,
    de.id_empleado_sk,
    dcv.id_canal_sk,
    dep.id_estado_sk as id_estado_pedido_sk,

    -- 2. Dimensiones Degeneradas
    p.id_pedido_nk as nro_pedido_dd,
    d.id_detalle_nk as nro_linea_dd,
    p.observaciones_pedido as observaciones_pedido_dd,

    -- 3. Métricas
    d.cantidad as cantidad_vendida,
    d.precio_unitario as precio_unitario_venta,
    d.subtotal as monto_subtotal_bruto,
    d.descuento as monto_descuento_linea,
    (d.subtotal - d.descuento) as monto_subtotal_neto,
    cast((d.subtotal / nullif(p.total_bruto, 0)) * p.impuesto as numeric(10,2)) as monto_impuesto_prorrateado,
    cast((d.subtotal / nullif(p.total_bruto, 0)) * p.propina as numeric(10,2)) as monto_propina_prorrateada

from detalle d
join pedidos p on d.id_pedido_nk = p.id_pedido_nk
-- Cruces SCD Tipo 2 (buscando la versión correcta en el tiempo)
left join {{ ref('dim_sucursal') }} ds on p.id_sucursal_nk = ds.id_sucursal_nk 
    and p.fecha_hora_transaccion >= ds.valido_desde and (p.fecha_hora_transaccion < ds.valido_hasta or ds.valido_hasta is null)
left join {{ ref('dim_producto') }} dp on d.id_producto_nk = dp.id_producto_nk 
    and p.fecha_hora_transaccion >= dp.valido_desde and (p.fecha_hora_transaccion < dp.valido_hasta or dp.valido_hasta is null)
left join {{ ref('dim_cliente') }} dc on p.id_cliente_nk = dc.id_cliente_nk 
    and p.fecha_hora_transaccion >= dc.valido_desde and (p.fecha_hora_transaccion < dc.valido_hasta or dc.valido_hasta is null)
left join {{ ref('dim_empleado') }} de on p.id_empleado_nk = de.id_empleado_nk 
    and p.fecha_hora_transaccion >= de.valido_desde and (p.fecha_hora_transaccion < de.valido_hasta or de.valido_hasta is null)
-- Cruces SCD Tipo 1 (Normales)
left join {{ ref('dim_canalventa') }} dcv on p.id_canal_nk = dcv.id_canal_nk
left join {{ ref('dim_estadopedido') }} dep on p.id_estado_nk = dep.id_estado_nk