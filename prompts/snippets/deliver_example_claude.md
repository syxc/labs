<example>
改动：core.py L42 增加空值检查。
验证：pytest tests/test_core.py -q 通过（12 passed）。
未验证项：并发场景未测。残余风险：上游 timeout 行为可能变化。
</example>
