 pwsh -File ./update-cloudproviderjson.ps1
 node --run build
 sudo docker build -t robholme/cloud-region-api .
