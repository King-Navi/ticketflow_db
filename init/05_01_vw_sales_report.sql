CREATE OR REPLACE VIEW vw_ticket_sales_details AS
SELECT 
    -- 1. Contexto (Organización y Evento)
    c.company_id,
    c.company_name AS organizacion,
    e.event_id,
    e.event_name AS evento,
    e.event_date AS fecha_evento,

    -- 2. Datos Financieros
    t.ticket_id,
    t.unit_price AS precio_pagado,
    es.base_price AS precio_original,

    -- 3. Ubicación
    sec.section_name AS zona,
    s.row_no AS fila,
    s.seat_no AS asiento,

    -- 4. Estado y Fecha de Venta
    ts.status_name AS estado_ticket,
    t.created_at AS fecha_venta

FROM 
    ticket t
    -- Relación con el Inventario
    JOIN event_seat es ON t.event_seat_id = es.event_seat_id
    -- Relación con el Evento y Empresa
    JOIN event e       ON es.event_id = e.event_id
    JOIN company c     ON e.company_id = c.company_id
    -- Relación con la Ubicación Física (Asiento)
    JOIN seat s        ON es.seat_id = s.seat_id
    JOIN section sec   ON s.section_id = sec.section_id
    -- Estado del ticket
    JOIN ticket_status ts ON t.ticket_status_id = ts.ticket_status_id