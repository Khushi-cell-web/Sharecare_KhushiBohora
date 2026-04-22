import urllib.request, json
try:
    req = urllib.request.Request("http://127.0.0.1:8000/api/donations/offers/", data=json.dumps({"donation_request": 1, "type": "material", "quantity": 1, "fulfillment_type": "volunteer_pickup", "pickup_location": "123 Test St"}).encode('utf-8'), headers={'Content-Type': 'application/json', 'Authorization': 'Bearer 0'})
    f = urllib.request.urlopen(req)
except Exception as e:
    try:
        print(e.read().decode())
    except:
        print(e)
