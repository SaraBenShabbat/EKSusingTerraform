
Here is the steps to create the EKS from terraform:

**Terraform**
- 
- Download and install terraform https://www.terraform.io/downloads.html
- go the the EKS folder (this tuto is actually in the folder)
- In the vars.tf file you can change the name of the cluster.
- $ terraform init (this will download all modules and init terraform)
- Now there is 3 commands to know:
   1. terraform apply (it will create everything you have in .tf files, which is actually the EKS)
   2. terraform plan (YOU HAVE TO USE THIS COMMAND  APPLY, this will show you  what terraform will create or delete)
   3. terraform destroy (to destroy what you created)
- So terraform apply will create the EKS.

**EKS configuration**
- 
 - First you have to download the AWS cli. https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html
 - Configure it with your ACCESS KEYS (full tuto on aws)
 - save your ~/.kube/config somewhere
 - $ aws eks --region region-code update-kubeconfig --name {cluster_name} (this will update your kubeconfig)
 - You should be able to see your new cluster : kubectl get all -A (you have to see something like core-dns but the pods arent created)
 - For now, the nodes aren't bound to the EKS so nothing will work, you have to add a little configuration.
 -   The terraform will automaticly create a configmap.yaml and put it in s3://vatbox-eks-terraform
 - copy it and then: $ kubectl create -f configmap.yaml
 - You should now be able to see the nodes rejoigning the cluster
 - $ kubectl get nodes --watch ( to see the nodes wait until they are ready)

