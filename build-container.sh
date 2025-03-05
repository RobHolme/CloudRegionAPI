 pwsh -FILE ./udpate-cloudproviderjson.ps1
 node --run build
 sudo docker build -t robholme/cloud-region-api .
