# Handoff TODO

Cross-repo backlog for Handoff (this API, `handoff-apps`, `handoff-marketing`).

Ideas for the next slices, roughly in order. One line each on purpose; whoever
picks one up scopes it.

1. Demo viewfinder in the courier app: a fake camera for browsers with a scene you can pan and tilt and a shutter button, used when no real camera is available.
2. Fix flagged rows in place on the merchant batch page, re-validating and re-geocoding on save instead of re-uploading the file.
3. Zones and pricing: postal-prefix zones with per-stop prices, price each order when a batch settles, show prices on batch pages, editable pricing table for ops.
4. Public tracking page for recipients, linked from the delivery emails, with ETA and proof photo.
5. Courier signup steps: application, documents, agreements, vehicle, then ops approval.
6. Courier availability, and only offer routes to couriers who are available that day.
7. Auto-offer routes after each merchant's cutoff, and expire stale offers, on a schedule.
8. Live courier location from the app to the API, shown on the ops routes page and the tracking page.
9. Weekly, biweekly, and monthly merchant invoices as PDFs.
10. Courier payouts: weekly runs with a per-route breakdown in the app.
11. Incidents: courier reports a problem, ops resolves it, merchant is told.
12. Ops merchants page: edit pickup address, cutoff, contacts, and users; approve new merchants.
13. Thermal labels PDF per batch from the merchant portal.
14. "Courier is a few stops away" email to recipients during a route.
15. Realtime updates on the ops routes page and batch pages instead of polling.
16. Address bank from real open data instead of generated street segments.
17. Boot all three repos in a Gently sandbox and fix whatever the apps.yml files get wrong.
18. Legacy seasoning: an older v0 API namespace with jbuilder views, a few one-off fix jobs, pending specs, a stale README section.
19. Merchant API keys and a JSON orders endpoint, so a store can push orders without a CSV.
20. Reports for merchants and ops: stops, failures, and returns by week.
