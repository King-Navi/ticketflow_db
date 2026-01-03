CREATE OR REPLACE VIEW vw_organization_sales_report AS
SELECT 
    c.company_id,
    c.company_name AS organizacion,
    e.event_id,
    e.event_name AS evento,
    e.event_date AS fecha_evento,
    COUNT(t.ticket_id) AS cantidad_boletos_vendidos,
    COALESCE(SUM(t.unit_price), 0) AS total_ingresos

FROM 
    event e
    JOIN company c ON e.company_id = c.company_id
    JOIN event_seat es ON e.event_id = es.event_id
    LEFT JOIN ticket t ON es.event_seat_id = t.event_seat_id
    LEFT JOIN ticket_status ts ON t.ticket_status_id = ts.ticket_status_id

WHERE 
    (ts.status_name IS NULL OR ts.status_name IN ('sold', 'checked_in'))

GROUP BY 
    c.company_id, 
    c.company_name, 
    e.event_id, 
    e.event_name, 
    e.event_date;