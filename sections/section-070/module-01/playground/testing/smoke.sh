#!/usr/bin/env bash
set -euo pipefail
test "$(kubectl config current-context)" = "kind-astro-ats-029-playground-070-01"
practice_directory="$(mktemp -d)"
cleanup() {
  if [[ -n "${PORT_FORWARD_PID:-}" ]]; then kill "$PORT_FORWARD_PID" 2>/dev/null || true; fi
  rm -rf "$practice_directory"
}
trap cleanup EXIT
cd "$practice_directory"
wait_for_success() {
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if "$@"; then return 0; fi
    sleep 1
  done
  return 1
}

mkdir -p "$(dirname serviceaccount-observer.yaml)"
cat > serviceaccount-observer.yaml <<'CKAD_FILE_END'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: observer
  namespace: starfleet
CKAD_FILE_END
mkdir -p "$(dirname role-pod-reader.yaml)"
cat > role-pod-reader.yaml <<'CKAD_FILE_END'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: starfleet
rules:
- apiGroups:
  - ''
  resources:
  - pods
  verbs:
  - get
  - list
CKAD_FILE_END
mkdir -p "$(dirname rolebinding-observer.yaml)"
cat > rolebinding-observer.yaml <<'CKAD_FILE_END'
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: observer-read
  namespace: starfleet
subjects:
- kind: ServiceAccount
  name: observer
  namespace: starfleet
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
CKAD_FILE_END
kubectl apply -f serviceaccount-observer.yaml -f role-pod-reader.yaml -f rolebinding-observer.yaml
kubectl -n starfleet set serviceaccount deployment/probe observer
kubectl -n starfleet rollout status deployment/probe --timeout=120s
kubectl -n starfleet get pods -l app=probe -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.serviceAccountName}{"\n"}{end}'
kubectl -n starfleet exec deployment/probe -- python -c 'from pathlib import Path; import ssl,urllib.request,json; root=Path('"'"'/var/run/secrets/kubernetes.io/serviceaccount'"'"'); request=urllib.request.Request('"'"'https://kubernetes.default.svc/api/v1/namespaces/starfleet/pods'"'"',headers={'"'"'Authorization'"'"':'"'"'Bearer '"'"'+(root/'"'"'token'"'"').read_text()}); context=ssl.create_default_context(cafile=str(root/'"'"'ca.crt'"'"')); response=json.load(urllib.request.urlopen(request,context=context)); print('"'"'visible-pods='"'"'+str(len(response['"'"'items'"'"'])))'
kubectl auth can-i get secrets -n starfleet --as=system:serviceaccount:starfleet:observer || true
kubectl -n starfleet get role pod-reader -o yaml
test "$(kubectl -n starfleet get deploy probe -o jsonpath='{.spec.template.spec.serviceAccountName}')" = observer
printf 'ATS029/070/01: live practice checks passed\n'
