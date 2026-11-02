import json,subprocess

def run(*args):
    return subprocess.run(["kubectl",*args],check=True,capture_output=True,text=True,timeout=15).stdout.strip()

def get(kind,name):
    return json.loads(run("-n","starfleet","get",kind,name,"-o","json"))

def can(verb,resource,namespace,identity):
    result=subprocess.run(["kubectl","auth","can-i",verb,resource,"-n",namespace,identity],capture_output=True,text=True,timeout=15)
    assert result.returncode in (0,1) and result.stdout.strip() in ("yes","no"), "Authorization check failed"
    return result.returncode==0 and result.stdout.strip()=="yes"

role=get("role","pod-reader")
rules=role.get("rules",[])
assert len(rules)==1, "Keep one narrow rule"
rule=rules[0]
assert rule.get("apiGroups")==[""] and rule.get("resources")==["pods"] and set(rule.get("verbs",[]))=={"get","list","watch"}, "Grant only core Pod reads"
assert not rule.get("nonResourceURLs") and not rule.get("resourceNames"), "Allow the complete Pod collection"
binding=get("rolebinding","shuttle-pod-reader")
assert binding["roleRef"]=={"apiGroup":"rbac.authorization.k8s.io","kind":"Role","name":"pod-reader"}, "Bind the required Role"
assert binding["subjects"]==[{"kind":"ServiceAccount","name":"shuttle","namespace":"starfleet"}], "Bind only the required identity"
identity="--as=system:serviceaccount:starfleet:shuttle"
for verb in ("get","list","watch"):
    assert can(verb,"pods","starfleet",identity), "Required Pod read denied"
for verb,resource,namespace in (("create","pods","starfleet"),("delete","pods","starfleet"),("get","secrets","starfleet"),("list","pods","outpost"),("get","nodes","starfleet")):
    assert not can(verb,resource,namespace,identity), "Excess permission granted"
print("Required resource contract and behavior verified")
