- Initier le Powerpoint
- faire le point des étudiants sur gitlab
- Elaborer un plan

-```
+----------------------+
| GitLab |
| (central partagé) |
+----------+-----------+
|
v
+---------+----------+
| Terraform (IaC) |
+---------+----------+
|
+--------------+------------------+
| |
+--------+--------+ +--------+--------+
| Filière VM | | Filière K8s |
| (Push CD) | | (GitOps) |
+-----------------+ +-----------------+
| VM App | | K8s Cluster |
| VM Monitoring | | ArgoCD |
+-----------------+ | Prom/Grafana |
+-----------------+
