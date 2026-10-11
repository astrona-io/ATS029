# Contributing

Read CLAUDE.md and preserve its shared ATS015 prefix. The current CKAD scope includes module playgrounds and guided practice. Keep concept teaching, section introductions, module summaries and reusable YAML questions. No new graded labs are included.

Use one self-contained environment per active module. Pin the kind node image, scope bootstrap to its expected private context and enable the actual dependencies an exercise needs. Policy objects require enforcement; metrics require metrics-server; Ingress requires a compatible controller. Preserve source and workload identity when comparing results.

Put the launch marker on the landing, one renew marker before the first practical step and a destroy marker at the end of the summary. Write complete input files in learner pages before applying them. Do not send learners to hidden playground files. Keep exercises bounded and use observed outputs; static validation does not justify invented runtime results.

Run Astrona config validation, shell syntax checks, the preparation content verifier and content-sync checks. Each playground's testing/smoke.sh replays its practice and checks live outcomes. Execute it only in the corresponding isolated environment, then destroy the environment. Record actual results and maintain any unresolved runtime limitations.
