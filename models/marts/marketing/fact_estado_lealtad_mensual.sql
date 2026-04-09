{{ config(materialized='table') }}
with lealtad as (select * from {{ ref('stg_mongodb__programa_lealtad') }})

select
    cast(to_char(l.fecha_actualizacion, 'YYYYMMDD') as integer) as id_fecha_cierre_mes_sk,
    dc.id_cliente_sk,

    l.nivel_lealtad as nivel_lealtad_dd,

    l.puntos_acumulados as puntos_disponibles_cierre,
    l.puntos_acumulados as puntos_acumulados_historicos, -- Requiere lógica histórica avanzada
    0 as variacion_puntos_mes -- Placeholder para lógica de LAG()

from lealtad l
left join {{ ref('dim_cliente') }} dc on l.id_cliente_nk = dc.id_cliente_nk and dc.es_actual = true