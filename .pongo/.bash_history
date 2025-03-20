kms
kms
exit
kms
ls
exit
kms
ps -aux
exit
kms
ps
curl -s http://localhost:1026/version
exit
curl -X GET http://localhost:1026/version
exit
ps
ps -aux
netstat -n
exit
kms
curl -X GET http://localhost:8000
curl -X GET http://localhost:1026
netstat -i
netstat -na
curl -X GET http://orion:1026
curl -X GET http://orion:1026/version
curl -i -X POST http://localhost:8001/services --data "name=orion" --data "url=http://orion:1026"
curl -i -X POST http://localhost:8001/services/orion/routes --data "hosts[]=orion.example.com"
curl -i -X POST http://localhost:8001/services/orion/plugins --data "name=orion2GeoJSON"
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/version
# エンティティの作成
curl -X POST   'http://localhost:8000/orion/v2/entities'   -H 'Content-Type: application/json'   -d '{
    "id": "Room1",
    "type": "Room",
    "temperature": {
      "value": 23,
      "type": "Float"
    },
    "location": {
      "value": {
        "type": "Point",
        "coordinates": [13.3986112, 52.554699]
      },
      "type": "geo:json"
    }
  }'
curl -X POST   'http://localhost:8000/orion/v2/entities'   -H 'Content-Type: application/json'   -d '{
    "id": "Room1",
    "type": "Room",
    "temperature": {
      "value": 23,
      "type": "Float"
    },
    "location": {
      "value": {
        "type": "Point",
        "coordinates": [13.3986112, 52.554699]
      },
      "type": "geo:json"
    }
  }'
curl -X POST   'http://orion:1026/v2/entities'   -H 'Content-Type: application/json'   -d '{
    "id": "Room1",
    "type": "Room",
    "temperature": {
      "value": 23,
      "type": "Float"
    },
    "location": {
      "value": {
        "type": "Point",
        "coordinates": [13.3986112, 52.554699]
      },
      "type": "geo:json"
    }
  }'
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities | jq
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/orion/v2/entities | jq
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/orion/v2/entities
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/orion/version
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/orion/version
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/version
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
jq
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
exit
kms
pwd
ls
ls -la
ls spec
ls -la
pongo
busted
exit
exit
kms
curl -i -X POST http://localhost:8001/services --data "name=orion" --data "url=http://orion:1026"
curl -i -X POST http://localhost:8001/services/orion/routes --data "hosts[]=orion.example.com"
curl -i -X POST http://localhost:8001/services/orion/plugins --data "name=orion2GeoJSON"
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/version
curl -X POST   'http://localhost:8000/v2/entities'   -H 'Content-Type: application/json'   -d '{
    "id": "Room1",
    "type": "Room",
    "temperature": {
      "value": 23,
      "type": "Float"
    },
    "location": {
      "value": {
        "type": "Point",
        "coordinates": [13.3986112, 52.554699]
      },
      "type": "geo:json"
    }
  }'
curl -X POST   'http://orion:1026/v2/entities'   -H 'Content-Type: application/json'   -d '{
    "id": "Room1",
    "type": "Room",
    "temperature": {
      "value": 23,
      "type": "Float"
    },
    "location": {
      "value": {
        "type": "Point",
        "coordinates": [13.3986112, 52.554699]
      },
      "type": "geo:json"
    }
  }'
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/version
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities | jq
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
curl -i -X GET --header "Host: orion.example.com" http://localhost:8000/v2/entities
exit
