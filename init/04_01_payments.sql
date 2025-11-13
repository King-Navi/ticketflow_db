-- Crea payment_method + card en una sola llamada
CREATE OR REPLACE FUNCTION create_card_with_payment_method(
  p_attendee_id   integer,
  p_card_token    varchar,
  p_card_brand    varchar,
  p_last4         char(4),
  p_exp_month     smallint,
  p_exp_year      smallint
)
RETURNS TABLE (
  payment_method_id integer,
  card_id           integer
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Validar que el attendee exista
  PERFORM 1
  FROM attendee
  WHERE attendee_id = p_attendee_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Attendee % does not exist', p_attendee_id
      USING ERRCODE = 'foreign_key_violation';
  END IF;

  -- 1) Crear payment_method
  INSERT INTO payment_method (attendee_id)
  VALUES (p_attendee_id)
  RETURNING payment_method.payment_method_id
    INTO payment_method_id;

  -- 2) Crear card ligada a ese payment_method
  INSERT INTO card (
    payment_method_id,
    card_token,
    card_brand,
    last4,
    exp_month,
    exp_year
  )
  VALUES (
    payment_method_id,
    p_card_token,
    p_card_brand,
    p_last4,
    p_exp_month,
    p_exp_year
  )
  RETURNING card.card_id
    INTO card_id;

  -- regresamos la fila (payment_method_id, card_id)
  RETURN;
END;
$$;
