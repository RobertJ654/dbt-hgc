with source as (select * from {{ source('raw_rrhh', 'cargos') }})
select
    id_cargo as id_cargo_nk,
    titulo as titulo_cargo,
    id_departamento as id_departamento_nk,
    cast(es_operativo as boolean) as es_operativo
from source