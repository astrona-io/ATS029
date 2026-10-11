#!/usr/bin/env bash
set -euo pipefail
test "$(kubectl config current-context)" = "kind-astro-ats-029-playground-080-01"
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

mkdir -p "$(dirname pod-restricted-reader.yaml)"
cat > pod-restricted-reader.yaml <<'CKAD_FILE_END'
apiVersion: v1
kind: Pod
metadata:
  name: restricted-reader
  namespace: starfleet
spec:
  containers:
  - name: reader
    image: docker.io/library/busybox:1.37.0
    command:
    - sh
    - -c
    - sleep 3600
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: scratch
      mountPath: /scratch
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  volumes:
  - name: scratch
    emptyDir: {}
CKAD_FILE_END
kubectl apply -f pod-restricted-reader.yaml
kubectl -n starfleet wait --for=condition=Ready pod/restricted-reader --timeout=120s
kubectl -n starfleet exec restricted-reader -- id
kubectl -n starfleet exec restricted-reader -- sh -c 'printf allowed > /scratch/result; cat /scratch/result'
if kubectl -n starfleet exec restricted-reader -- sh -c 'printf denied > /root-file'; then printf 'Root filesystem unexpectedly writable\n' >&2; exit 1; fi
kubectl -n starfleet get pod restricted-reader -o yaml
kubectl -n starfleet exec restricted-reader -- cat /proc/1/status
test "$(kubectl -n starfleet exec restricted-reader -- id -u)" = 1000
printf 'ATS029/080/01: live practice checks passed\n'
