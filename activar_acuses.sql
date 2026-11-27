BEGIN;
-- Conserva la función de registro original y sus validaciones.
-- La nueva función devuelve únicamente el resumen del registro recién creado.
CREATE OR REPLACE FUNCTION public.registrar_inmueble_con_acuse(
    p_contrasena_apf TEXT, p_usa_aa BOOLEAN, p_grupos JSONB
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_id UUID;
    v_acuse JSONB;
BEGIN
    v_id := public.registrar_inmueble(p_contrasena_apf, p_usa_aa, p_grupos);
    SELECT jsonb_build_object(
        'apf', i.contrasena_apf,
        'date', i.fecha_registro,
        'aa', i.usa_aa,
        'count', coalesce(sum(e.numero_equipos), 0),
        'tr', coalesce(sum(e.capacidad_total_tr), 0)
    ) INTO v_acuse
    FROM public.inmuebles i
    LEFT JOIN public.equipos_aa e ON e.inmueble_id = i.id
    WHERE i.id = v_id
    GROUP BY i.id, i.contrasena_apf, i.fecha_registro, i.usa_aa;
    IF v_acuse IS NULL THEN
        RAISE EXCEPTION 'No se pudo generar el resumen del registro.';
    END IF;
    RETURN v_acuse;
END;
$$;
REVOKE ALL ON FUNCTION public.registrar_inmueble_con_acuse(TEXT, BOOLEAN, JSONB) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.registrar_inmueble_con_acuse(TEXT, BOOLEAN, JSONB) TO anon;
COMMIT;
