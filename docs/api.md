# API sözleşmesi v1

GET `/v1/feed/today?city=Ankara`
- Bugünün kişiselleştirilmiş feed'i.

GET `/v1/events/{id}`
- Etkinlik detay.

GET `/v1/places/{id}`
- Mekan detay.

GET `/v1/search?q=...&city=Ankara`
- Arama.

POST `/v1/interactions`
- view/save/share/navigation/ticket_click vb.

POST `/v1/planner`
Body örneği:
```json
{"date":"2026-09-06","city":"Ankara","budget":500,"people":2,"mood":"romantic","start_time":"18:00","end_time":"23:00"}
```

POST `/v1/business/offers`
- İşletme kampanyası oluşturma.
