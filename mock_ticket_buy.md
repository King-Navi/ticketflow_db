Requisitos

Tener el ID del evento (por ejemplo: 3).

El evento debe estar en estado on_sale antes de reservar/comprar.

1) Tener el event_id

Ejemplo:

{
  "event_id": 3
}

2) Poner el evento en on_sale

Endpoint:

{{HOST}}:{{PORT_HTTP}}{{eventRoute}}/:eventId/status


Body:

{
  "status": "on_sale"
}


Ejemplo con eventId = 3:

{{HOST}}:{{PORT_HTTP}}{{eventRoute}}/3/status

3) Obtener asientos del evento

Endpoint:

{{HOST}}:{{PORT_HTTP}}{{eventSeatRoute}}/:eventId/seats


Ejemplo con eventId = 3:

{{HOST}}:{{PORT_HTTP}}{{eventSeatRoute}}/3/seats


De aquí eliges un event_seat_id disponible (por ejemplo 7).

4) Reservar el asiento

Endpoint:

{{HOST}}:{{PORT_HTTP}}{{reserveRoute}}/reserve


Body (ejemplo):

{
  "event_id": 3,
  "event_seat_id": 7
}

5) Comprar el/los asientos

Endpoint:

{{HOST}}:{{PORT_HTTP}}{{ticketRoute}}/buy


Body (ejemplo):

{
  "event_seat_id": [7]
}


✅ En la respuesta de este endpoint vas a recibir (o podrás extraer) el:

PAYMENT_INTENT_ID (Stripe)

Ejemplo:

pi_3SlwGeDfP4KV3h2x3MaEj1Wx

6) Confirmar el Payment Intent con Stripe CLI (en Docker)

Entrar al contenedor:

docker exec -it ticketflow_db-stripe-listener-1 sh


Asegúrate de estar logeado (si no lo estás):

stripe login


Confirmar el pago:

stripe payment_intents confirm <PAYMENT_INTENT_ID> --payment-method pm_card_visa


Ejemplo real:

stripe payment_intents confirm pi_3SlwGeDfP4KV3h2x3MaEj1Wx --payment-method pm_card_visa