# Check kubectl version
kubectl version

# View cluster information
kubectl cluster-info

# List all nodes in the cluster
kubectl get nodes

# List all namespaces
kubectl get namespaces

# List all pods in all namespaces
kubectl get pods --all-namespaces

# List all services in all namespaces
kubectl get services --all-namespaces

# Check the status of the Kubernetes components
kubectl get componentstatuses

# Run a simple test pod using a minimal image
kubectl run test-nginx --image=nginx:alpine --restart=Never

# Wait for 30 seconds to allow the pod to start
Start-Sleep -Seconds 30

# Check if the pod was created and its status
kubectl get pods

# View the logs of the test pod (if it's running)
kubectl logs test-nginx

# Delete the test pod
kubectl delete pod test-nginx

# List all persistent volumes
kubectl get pv

# List all persistent volume claims
kubectl get pvc

# Check available storage classes
kubectl get storageclass

# Check for any events that might indicate issues
kubectl get events --sort-by='.lastTimestamp'

# Display detailed information about the cluster
kubectl describe node docker-desktop