output "gcloud connect command" {
  value = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.zone} --project ${var.project}"
}

output "enable access to dashboard" {
  value = "kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard"
}
