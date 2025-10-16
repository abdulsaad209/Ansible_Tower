You can install Ansible AWX version 24.6.0 on In Kubernetes Cluster.
Requirements:
API Server with:
* Minimum 2GB RAM and 1 Core CPU

Worker Node:
* Minimum 4GB-6GB RAM and 3 Core CPU

## Install Ansible AWX 24.6.0 on kubernetes Cluster
### Clone the code repo and Deploy AWX
```
git clone https://github.com/ansible/awx-operator.git 
cd awx-operator 
git checkout 2.19.0
export NAMESPACE=ansible-awx
make deploy
cp awx-demo.yml ansible-awx.yml
```
### Make changes in Kubernetes manifests

vim ansible-awx.yml
```
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: ansible-awx
  namespace: ansible-awx
spec:
  service_type: nodeport
  projects_persistence: false
  postgres_storage_class: local-storage
```

vim awx-pv.yml
```
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  hostPath:
    path: /mnt/storage
```

vim awxstorage-class.yml
```
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
  namespace: ansible-awx
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```
Create ansible-awx namespace
```
kubectl create ns ansible-awx
```

#### Create Mount Point Directories with Necessary Permissions on Worker Node
Run below commands on Worker Node of Cluster
```
sudo mkdir -p /mnt/storage
sudo chown -R 26:26 /mnt/storage   # 26 is the postgres UID in sclorg images
sudo chmod 700 /mnt/storage
```

#### Create Resources through Kubernetes Manifests
```
kubectl apply -f ansible-awx.yml
kubectl apply -f awxstorage-class.yml
kubectl apply -f awx-pv.yml
```
Set ansible-awx namespace as default for easyness
```
kubectl config set-context --current --namespace=$NAMESPACE
```

#### Keep patience and keep monitoring Logs using below command 
```
kubectl logs -f deployments/awx-operator-controller-manager -c awx-manager
```

Also keep an eye on kubelet on worker nodes
```
journalctl -u kubelet -f
```

#### After setup everything verify resources and get intial password and login on AWX Console
Check resources
```
kubectl get all -n ansible-awx
```

* Get Initial Password
User: Admin
Password: <Get by running below command)
```
kubectl get secret ansible-awx-admin-password -o jsonpath="{.data.password}" | base64 --decode; echo 
```
Get external IP and Port to access AWX Web UI
```
kubectl get svc
```


  
