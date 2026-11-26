#!/usr/bin/env bash
set -euxo pipefail

work_dir=$(mktemp -d)
export GILT_CACHE_DIRECTORY="${work_dir}/cache"

git init --quiet "${work_dir}/source"
git -C "${work_dir}/source" config user.name "Conda Test"
git -C "${work_dir}/source" config user.email "conda-test@example.com"
printf 'expected overlay content\n' > "${work_dir}/source/payload.txt"
git -C "${work_dir}/source" add payload.txt
git -C "${work_dir}/source" -c commit.gpgsign=false commit --quiet -m "Add overlay payload"
git -C "${work_dir}/source" -c tag.gpgsign=false tag -a -m "Test tag" test-tag
printf 'content at untagged HEAD\n' > "${work_dir}/source/payload.txt"
git -C "${work_dir}/source" add payload.txt
git -C "${work_dir}/source" -c commit.gpgsign=false commit --quiet -m "Change payload after tag"

cd "${work_dir}"
cat > gilt.yml <<EOF
- git: file://${work_dir}/source
  version: test-tag
  dst: result/
EOF

gilt overlay
git -C "${work_dir}/source" show test-tag:payload.txt | cmp - result/payload.txt
