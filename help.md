```bash
docker exec -it ticketflow_db-stripe-listener-1 sh
```

```bash
stripe login
```

#Para escuchar los webhooks en local (si usas tunnel u otra cosa, adaptamos luego):
```bash
stripe listen --forward-to http:/localhost:6970/webhooks/stripe
```

#Ahora, para disparar un evento de éxito de pago, Stripe CLI tiene comandos tipo:
```bash
stripe trigger payment_intent.succeeded
```
##Para uno real para test es 

```bash
stripe payment_intents confirm <PAYMENT_INTENT_ID> --payment-method pm_card_visa
```

#Refund completo (recomendado: por PaymentIntent)
```bash

stripe refunds create --payment-intent=pi_123
```


```bash
```


```bash
```



```bash
```


stripe payment_intents confirm pi_3SUHrpDfP4KV3h2x2SV1oBux --payment-method pm_card_visa