quota=get('resourcequota','practice-budget')
assert quota['status']['hard']['pods']=='5' and int(quota['status']['used']['pods'])>=3, 'Wait for actual quota accounting'
# Dry-run does not reserve capacity across requests, so ask for one request that is
# individually impossible: a deployment scale does not use Pod quota directly.
# Verify the quota's measured headroom, then rely on the API admission contract.
assert int(quota['status']['used']['pods'])<=5, 'Keep usage within the enforced budget'
