BEGIN;

-- 1. Declaramos variables para usar IDs dinámicos
DO $$
DECLARE
    v_company_id int;
    v_location_id int;
    v_event_status_id int;
    v_event_id int;
    v_seat_id_1 int;
    v_seat_id_2 int;
    v_es_id_1 int;
    v_es_id_2 int;
    v_payment_id int;
    v_ticket_status_sold int;
    v_event_seat_status_sold int;
BEGIN

    -- Obtener IDs existentes del seed anterior
    SELECT company_id INTO v_company_id FROM company WHERE company_name = 'Eventia Productions';
    SELECT event_location_id INTO v_location_id FROM event_location WHERE venue_name = 'Teatro Aurora';
    SELECT event_status_id INTO v_event_status_id FROM event_status WHERE code = 'on_sale';
    
    -- Obtener Payment ID del seed anterior (usando el stripe_id que pusiste)
    SELECT payment_id INTO v_payment_id FROM payment WHERE stripe_payment_intent_id = 'seed_pi_1';

    -- Obtener Status IDs
    SELECT ticket_status_id INTO v_ticket_status_sold FROM ticket_status WHERE status_name = 'sold';
    SELECT event_seat_status_id INTO v_event_seat_status_sold FROM event_seat_status WHERE status_name = 'sold';

    -- 2. CREAR EL EVENTO
    INSERT INTO event (
        event_name, category, description, event_date, start_time, end_time,
        company_id, event_location_id, event_status_id, created_at
    ) VALUES (
        'Concierto de Rock Clásico',
        'Music',
        'Un tributo a las leyendas.',
        CURRENT_DATE + INTERVAL '10 days', -- Será en 10 días
        '20:00:00',
        '23:00:00',
        v_company_id,
        v_location_id,
        v_event_status_id,
        NOW()
    ) RETURNING event_id INTO v_event_id;

    -- 3. ASIGNAR ASIENTOS AL EVENTO (Inventario)
    -- Tomamos 2 asientos físicos cualquiera del Teatro Aurora
    SELECT seat_id INTO v_seat_id_1 FROM seat s 
    JOIN section sec ON s.section_id = sec.section_id
    WHERE sec.event_location_id = v_location_id LIMIT 1;

    SELECT seat_id INTO v_seat_id_2 FROM seat s 
    JOIN section sec ON s.section_id = sec.section_id
    WHERE sec.event_location_id = v_location_id OFFSET 1 LIMIT 1;

    -- Insertamos en event_seat
    INSERT INTO event_seat (event_id, seat_id, base_price, event_seat_status_id)
    VALUES (v_event_id, v_seat_id_1, 50.00, v_event_seat_status_sold)
    RETURNING event_seat_id INTO v_es_id_1;

    INSERT INTO event_seat (event_id, seat_id, base_price, event_seat_status_id)
    VALUES (v_event_id, v_seat_id_2, 50.00, v_event_seat_status_sold)
    RETURNING event_seat_id INTO v_es_id_2;

    -- 4. CREAR TICKETS (Venta confirmada)
    -- Usamos el payment_id que ya existía. Precio unitario 50.00 c/u (Total 100.00 coincide con tu payment)
    INSERT INTO ticket (
        category_label, seat_label, unit_price, payment_id, ticket_status_id, event_seat_id
    ) VALUES 
    ('General', 'Asiento 1', 50.00, v_payment_id, v_ticket_status_sold, v_es_id_1),
    ('General', 'Asiento 2', 50.00, v_payment_id, v_ticket_status_sold, v_es_id_2);

END $$;

COMMIT;