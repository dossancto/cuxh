# CUXH

A simple tool for converting raw curl into xh (maybe httpie CLI) syntax.

## Usage

```bash
cuxh  "curl -X POST \"https://httpbin.org/post\" -H  \"accept: application/json\" --data-raw '{\"property1\": \"1\"}' -H 'Authorization: Bearer 123'"
# Output: xhs POST https://httpbin.org/post property1='1' --bearer '123'
```
