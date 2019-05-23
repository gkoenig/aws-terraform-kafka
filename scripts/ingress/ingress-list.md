# List available Ingress/Service endpoints

Sometimes it might be necessary to quickly produce a list of endpoints provided by the `Ingress` controller and `Services` of your Kubernetes cluster.

- `./ingress-list.sh` produces a plain text list
- `./ingress-list.sh html` produces a simple HTML file, with links to all resources
- `./ingress-list.sh csv` helps you creating the CSV file for the global monitoring.  
  You can configure settings like your project name, health endpoints, etc. in `ingress-list-csv.gotemplate`.
