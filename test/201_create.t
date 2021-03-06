#!/bin/sh

test_description="Create new repos"

. ./setup.sh

test_expect_success "Clone source repos" "
    git clone https://github.com/seveas/whelk.git &&
    # Contains a tree that has a .git directory
    git -C whelk update-ref -d refs/remotes/origin/gh-pages &&
    git clone https://github.com/seveas/hacks.git
"

for spindle in hub lab bb; do
    test_expect_success $spindle "Cleanup ($spindle)" "
        (export DEBUG=1; git_${spindle}_1 test-cleanup --repos)
    "
done

for spindle in hub lab bb; do
    test_expect_success $spindle "Create repo ($spindle)" "
        ( cd whelk &&
        echo whelk > expected &&
        git_${spindle}_1 create &&
        git_${spindle}_1 repos | sed -e 's/ .*//' > actual &&
        test_cmp expected actual &&
        git_1 push $(spindle_remote git_${spindle}_1) refs/remotes/origin/*:refs/heads/* refs/tags/*:refs/tags/* )
    "
done;

test_expect_success hub,lab,bb "Creating a repo does not overwrite 'origin'" "
    cat >expected <<EOF &&
bitbucket	git@bitbucket.org:XXX/whelk.git (fetch)
bitbucket	git@bitbucket.org:XXX/whelk.git (push)
github	git@github.com:XXX/whelk.git (fetch)
github	git@github.com:XXX/whelk.git (push)
gitlab	git@gitlab.com:XXX/whelk.git (fetch)
gitlab	git@gitlab.com:XXX/whelk.git (push)
origin	https://github.com/seveas/whelk.git (fetch)
origin	https://github.com/seveas/whelk.git (push)
EOF
    git -C whelk remote -v > actual &&
    sort
    sed -e 's@:[^/]\\+/@:XXX/@' -i actual &&
    test_cmp expected actual
"

test_expect_success lab_local "Create a repo with a GitLab local install set as default" "
    (export DEBUG=1; git_lab_local test-cleanup --repos) &&
    host=\$(git_lab_local config host) &&
    user=\$(git_lab_local config user) &&
    token=\$(git_lab_local config token) &&
    echo \"\$host \$user \$token\" &&
    git_lab config host \$host &&
    git_lab config user \$user &&
    git_lab config token \$token &&
    (cd whelk && git_lab create)
"

for spindle in hub lab bb; do
    test_expect_success $spindle "Create repo with description ($spindle)" "
        ( cd hacks &&
        echo 'Hacks repo' > expected &&
        git_${spindle}_1 create --description='Hacks repo' &&
        git_${spindle}_1 repos | sed -ne 's/.*H/H/p' > actual &&
        test_cmp expected actual )
    "
done;

test_expect_failure "Create private repo" "false"
test_expect_failure "Create with --name" "false # upsets set-origin"

test_done

# vim: set syntax=sh:
