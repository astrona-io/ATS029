setting=get('probesetting','greeting')
assert setting.get('status',{}).get('ready') is True, 'Wait for controller reconciliation'
controller=get('deployment','settings-controller')
assert controller.get('status',{}).get('availableReplicas',0)>=1, 'Keep the controller available'
