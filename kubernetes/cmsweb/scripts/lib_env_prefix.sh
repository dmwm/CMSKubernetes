# lib_env_prefix.sh
#
# Maps a `kubectl config get-clusters` cluster name to this cluster's
# `env_prefix` (used for the `env`/`k8s-<name>` label on kube-eagle,
# logstash, and prometheus.yaml — see deploy_monitoring() in deploy.sh).
#
# Split into its own file so the mapping logic can be unit-tested in
# isolation (see test_env_prefix.sh) without sourcing the rest of deploy.sh,
# which has side effects (kubectl/openstack calls) and expects a full set of
# environment variables to already be set.
#
# Replaces a previous hardcoded if-chain (one `if` per cmsweb-testN, only
# covering test1-test12) that was both incomplete AND actively buggy: since
# each check was a plain substring match (`*cmsweb-test1*` also matches
# "cmsweb-test10", "cmsweb-test18", etc.) done as independent `if`s rather
# than `elif`, any cluster number without its own explicit branch silently
# collided with a lower-numbered one instead of falling through to a safe
# default — e.g. cmsweb-test13/14/18 all resolved to env_prefix=test1 (colliding
# with the real test1), and cmsweb-test20/21 resolved to test2 (colliding with
# the real test2).

# Returns the empty string when cluster_name doesn't match anything recognized
# (neither "cmsweb-auth" nor "cmsweb-test<N>") -- callers must treat that as a
# hard error, not silently fall back to a generic value. See deploy.sh's
# caller for the FORCE_ENV_PREFIX override for a deliberate new naming scheme.
compute_env_prefix() {
    local cluster_name="$1"
    local env_prefix=""

    if [[ "$cluster_name" == *"cmsweb-auth"* ]] ; then
        env_prefix="auth"
    elif [[ "$cluster_name" =~ cmsweb-test([0-9]+) ]] ; then
        env_prefix="test${BASH_REMATCH[1]}"
    fi

    echo "$env_prefix"
}
