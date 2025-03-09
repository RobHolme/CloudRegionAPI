# build a local container. 

# Optional - uncomment next line to update JSON cloud provider definitions. Not required as files are updated weekly via GitHub action. Requires Powershell > v7
# pwsh -File ./update-cloudproviderjson.ps1

# build the node solution
sudo node --run build

# build the local container
sudo docker build -t robholme/cloud-region-api .
