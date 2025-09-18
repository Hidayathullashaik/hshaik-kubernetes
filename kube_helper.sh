bind '"\C-l": clear-screen'

# ----------------- Kubernetes Env Display -----------------
kenv() {
    echo "----- Kubernetes Environment Variables -----"
    local vars=("NAMESPACE" "APP" "KUBECONFIG" "KUBE_EDITOR" "KUBECTL_PLUGINS_PATH")
    for var in "${vars[@]}"; do
        if [[ -n "${!var}" ]]; then
            printf "%-20s = %s\n" "$var" "${!var}"
        else
            printf "%-20s = (not set)\n" "$var"
        fi
    done
    echo "--------------------------------------------"
}

# ---------------- Dynamically Adjustable Namespace & App values ----------------

nms() { export NAMESPACE="$1"; echo "NAMESPACE set to $NAMESPACE"; }
app() { export APP="$1"; echo "APP set to $APP"; }

export NAMESPACE=default
export APP=nginx

# --------------- kubectl completion ------------------
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k

# ---------------- Utility functions ------------------
context()     { kubectl config get-contexts "$@"; }
contextcc()   { kubectl config current-context; }
contextuse()  { kubectl config use-context "$@"; }
contextset()  { kubectl config set-context --current --namespace="$NAMESPACE"; }

# ---------------- Dynamic helpers -------------------
get()     { kubectl get -n "$NAMESPACE" "$@"; }
ns()      { kubectl get ns "$@"; }
po()      { kubectl -n "$NAMESPACE" get po -o wide "$@"; }
poa()     { kubectl get po -A "$@"; }
pox()     { kubectl -n "$NAMESPACE" delete po "$@"; }
deploy()  { kubectl -n "$NAMESPACE" get deploy -o wide "$@"; }
deploya() { kubectl get deploy -A "$@"; }
svc()     { kubectl -n "$NAMESPACE" get svc -o wide "$@"; }
svca()    { kubectl get svc -A "$@"; }
sc()      { kubectl get sc "$@"; }
pv()      { kubectl get pv "$@"; }
pvc()     { kubectl -n "$NAMESPACE" get pvc "$@"; }
pvca()    { kubectl get pvc -A "$@"; }
all()     { kubectl -n "$NAMESPACE" get all "$@"; }
aall()    { kubectl get all -A "$@"; }
sys()     { kubectl -n kube-system get po -o wide "$@"; }
sysall()  { kubectl -n kube-system get all "$@"; }

# ---------------- Core helpers -------------------
ndr()     { kubectl describe node "$@"; }
apply()   { kubectl -n "$NAMESPACE" apply -f "$@"; }
dr()      { kubectl -n "$NAMESPACE" describe "$@"; }
delete()  { kubectl -n "$NAMESPACE" delete "$@"; }
edit()    { kubectl -n "$NAMESPACE" edit "$@"; }
logs()    { kubectl -n "$NAMESPACE" logs "$@"; }
it()      { kubectl -n "$NAMESPACE" exec -it "$@"; }

# ------------------- YAML generators (production-ready) -------------------

# Deployment
createdeploy() {
  kubectl create deployment "$APP" \
    --namespace="$NAMESPACE" \
    --image="$APP:latest" \
    --replicas=1 \
    --port=80 \
    --labels="app=$APP" \
    --dry-run=client -o yaml > "${APP}-deploy.yaml"
}

# Label Deployment
labeldeploy() {
  kubectl label deployment "$APP" app="$APP" --namespace="$NAMESPACE"
}

# Pod
createpo() {
  kubectl run "$APP" \
    --image="$APP:latest" \
    --restart=Never \
    --env="ENV=dev" \
    --port=80 \
    --labels="app=$APP" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml > "${APP}-pod.yaml"
}

# Service
createsvc() {
  kubectl expose deployment "$APP" \
    --port=80 --target-port=80 \
    --type=ClusterIP \
    --name="${APP}-svc" \
    --namespace="$NAMESPACE" \
    --labels="app=$APP" \
    --dry-run=client -o yaml > "${APP}-svc.yaml"
}

# Ingress
createingress() {
  kubectl create ingress "${APP}-ingress" \
    --namespace="$NAMESPACE" \
    --rule="example.com/=${APP}:80" \
    --class=nginx \
    --annotation="nginx.ingress.kubernetes.io/rewrite-target=/" \
    --labels="app=$APP" \
    --dry-run=client -o yaml > "${APP}-ingress.yaml"
}

# ConfigMap
createconfigmap() {
  kubectl create configmap "${APP}-config" \
    --from-literal=APP="$APP" \
    --namespace="$NAMESPACE" \
    --labels="app=$APP" \
    --dry-run=client -o yaml > "${APP}-config.yaml"
}

# Secret
createsecret() {
  kubectl create secret generic "${APP}-secret" \
    --from-literal=password=secret123 \
    --namespace="$NAMESPACE" \
    --labels="app=$APP" \
    --dry-run=client -o yaml > "${APP}-secret.yaml"
}

# Role
createrole() {
  kubectl create role "${APP}-role" \
    --verb=get,list,watch \
    --resource=pods \
    --namespace="$NAMESPACE" \
    --labels="app=$APP" \
    --dry-run=client -o yaml > "${APP}-role.yaml"
}

# RoleBinding
createrolebinding() {
  kubectl create rolebinding "${APP}-role-binding" \
    --role="${APP}-role" \
    --user=alice \
    --namespace="$NAMESPACE" \
    --labels="app=$APP" \
    --dry-run=client -o yaml > "${APP}-role-binding.yaml"
}

# CronJob
createcronjob() {
  kubectl create cronjob "${APP}-cron" \
    --schedule="*/5 * * * *" \
    --image="$APP:latest" \
    --restart=OnFailure \
    --namespace="$NAMESPACE" \
    --labels="app=$APP" \
    --dry-run=client -o yaml > "${APP}-cronjob.yaml"
}

# PodDisruptionBudget
createpdb() {
  kubectl create poddisruptionbudget "${APP}-pdb" \
    --min-available=1 \
    --selector="app=$APP" \
    --namespace="$NAMESPACE" \
    --labels="app=$APP" \
    --dry-run=client -o yaml > "${APP}-pdb.yaml"
}

# ResourceQuota
createquota() {
  kubectl create quota "${APP}-quota" \
    --hard="pods=5,cpu=2,memory=2Gi" \
    --namespace="$NAMESPACE" \
    --labels="app=$APP" \
    --dry-run=client -o yaml > "${APP}-quota.yaml"
}

# NetworkPolicy
createrule() {
  kubectl create networkpolicy "${APP}-netpolicy" \
    --namespace="$NAMESPACE" \
    --pod-selector="app=$APP" \
    --ingress \
    --labels="app=$APP" \
    --dry-run=client -o yaml > "${APP}-netpolicy.yaml"
}

# ServiceAccount
createsa() {
  kubectl create serviceaccount "${APP}-sa" \
    --namespace="$NAMESPACE" \
    --labels="app=$APP" \
    --dry-run=client -o yaml > "${APP}-sa.yaml"
}

# Token for ServiceAccount
createtoken() {
  kubectl create token "${APP}-token" \
    --serviceaccount="${APP}-sa" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml > "${APP}-token.yaml"
}


# ------------- Show env variables -------------------
kenv() {
    echo "----- Kubernetes Environment Variables -----"
    local vars=("NAMESPACE" "APP" "KUBECONFIG" "KUBE_EDITOR" "KUBECTL_PLUGINS_PATH")
    for var in "${vars[@]}"; do
        if [[ -n "${!var}" ]]; then
            printf "%-20s = %s\n" "$var" "${!var}"
        else
            printf "%-20s = (not set)\n" "$var"
        fi
    done
    echo "--------------------------------------------"
}

# ------------- Give completion to helpers -------------
for f in kg ns po poa deploy deploya svc svca sc pv pvc pvca all allA sys sysall \
          nodedr podr deploydr svcdr pvcdr applyf kd kx ke kl ki \
          createdeploy labeldeploy createpo createsvc createconfigmap \
          createsecret createingress createrole createrolebinding kenv \
          createcronjob createpdb createquota createrule createsa createtoken
do
  complete -F __start_kubectl $f
done
