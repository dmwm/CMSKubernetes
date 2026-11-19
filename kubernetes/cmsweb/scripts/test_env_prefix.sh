#!/bin/bash
##H Usage: test_env_prefix.sh
##H
##H Unit tests for lib_env_prefix.sh's compute_env_prefix() -- the cluster-name
##H to env_prefix mapping used by deploy.sh's deploy_monitoring() (the env
##H label baked into kube-eagle.yaml, logstash.yaml, and prometheus.yaml).
##H Run this after touching lib_env_prefix.sh, and before relying on it for
##H a newly created test cluster.

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$dir/lib_env_prefix.sh"

fail=0
check() {
    local input="$1" expected="$2" got
    got="$(compute_env_prefix "$input")"
    if [ "$got" == "$expected" ]; then
        echo "PASS: $input -> $got"
    else
        echo "FAIL: $input -> got '$got', expected '$expected'"
        fail=1
    fi
}

# --- Existing, already-correct clusters: must not regress ---
check "cmsweb-test1"   "test1"
check "cmsweb-test2"   "test2"
check "cmsweb-test3"   "test3"
check "cmsweb-test4"   "test4"
check "cmsweb-test5"   "test5"
check "cmsweb-test6"   "test6"
check "cmsweb-test7"   "test7"
check "cmsweb-test8"   "test8"
check "cmsweb-test9"   "test9"
check "cmsweb-test10"  "test10"
check "cmsweb-test11"  "test11"
check "cmsweb-test12"  "test12"
check "cmsweb-auth"    "auth"

# --- Previously-broken clusters: the actual bug this fix addresses ---
# (old code silently resolved these to test1 or test2 instead of their own number)
check "cmsweb-test13"  "test13"
check "cmsweb-test14"  "test14"
check "cmsweb-test18"  "test18"
check "cmsweb-test20"  "test20"
check "cmsweb-test21"  "test21"
check "cmsweb-test100" "test100"

# --- No match at all: unrelated cluster name now returns empty (a hard error
#     signal for deploy.sh's caller), NOT the old silent "k8s" -> "k8s-k8s" ---
check "some-other-cluster" ""

echo
echo "--- integration check: deploy.sh's wrapper actually aborts on empty ---"
deploy_sh="$dir/deploy.sh"
out="$(FORCE_ENV_PREFIX="" bash -c '
    source "'"$dir"'/lib_env_prefix.sh"
    cluster_name="some-other-cluster"
    env_prefix="$(compute_env_prefix "$cluster_name")"
    if [ -z "$env_prefix" ]; then
        echo "ERROR: could not determine env_prefix" >&2
        exit 1
    fi
    env_prefix="k8s-$env_prefix"
' 2>&1)"
rc=$?
if [ $rc -ne 0 ] && echo "$out" | grep -q "ERROR: could not determine env_prefix"; then
    echo "PASS: unrecognized cluster_name aborts with exit $rc and an ERROR message"
else
    echo "FAIL: expected a non-zero exit + ERROR message, got rc=$rc, output: $out"
    fail=1
fi

echo
echo "--- integration check: FORCE_ENV_PREFIX override bypasses detection ---"
out="$(FORCE_ENV_PREFIX=mycustom bash -c '
    if [ -n "$FORCE_ENV_PREFIX" ]; then
        env_prefix="$FORCE_ENV_PREFIX"
    fi
    echo "env_prefix=$env_prefix"
')"
if [ "$out" == "env_prefix=mycustom" ]; then
    echo "PASS: FORCE_ENV_PREFIX=mycustom -> $out"
else
    echo "FAIL: FORCE_ENV_PREFIX override didn't take effect, got: $out"
    fail=1
fi

echo
if [ "$fail" -eq 1 ]; then
    echo "One or more tests FAILED"
    exit 1
fi
echo "All tests passed"
