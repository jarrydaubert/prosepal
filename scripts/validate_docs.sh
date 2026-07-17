#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

python3 scripts/validate_feature_status.py

ruby <<'RUBY'
require "cgi"
require "find"
require "pathname"

root = Pathname.pwd
docs_root = root.join("docs")
index_path = docs_root.join("README.md")
errors = []

required = %w[
  docs/README.md
  docs/BACKLOG.md
  docs/DOCS_POLICY.md
  docs/guide/app-guide.html
  docs/product/overview.md
  docs/product/v1-launch-contract.md
  docs/product/capabilities.md
  docs/product/user-journeys.md
  docs/engineering/architecture.md
  docs/engineering/ai-generation.md
  docs/engineering/gateway-request-ledger.md
  docs/engineering/data-and-privacy.md
  docs/engineering/relationship-vault.md
  docs/engineering/auth-and-accounts.md
  docs/engineering/subscriptions.md
  docs/engineering/system-surfaces.md
  docs/operations/getting-started.md
  docs/operations/local-development.md
  docs/operations/staging.md
  docs/operations/release.md
  docs/operations/service-ownership.md
  docs/quality/testing.md
  docs/quality/ai-output-quality.md
  docs/quality/writing-quality-rubric.md
  docs/quality/accessibility.md
  docs/quality/release-evidence.md
  docs/reference/configuration.md
  docs/reference/generation-contract.md
  docs/reference/service-endpoints.md
  docs/reference/feature-status.jsonl
  docs/reference/feature-status.csv
  docs/history/README.md
]

required.each do |relative|
  errors << "missing required document: #{relative}" unless root.join(relative).file?
end

index = index_path.read
active_files = []
Find.find(docs_root.to_s) do |path|
  relative = Pathname(path).relative_path_from(docs_root).to_s
  if File.directory?(path)
    Find.prune if relative == "history"
    next
  end
  next if relative == "README.md"
  next if relative.start_with?("guide/assets/")
  next unless %w[.md .html .jsonl .csv].include?(File.extname(path))

  active_files << relative
end


active_files.sort.each do |relative|
  errors << "active document is not indexed in docs/README.md: docs/#{relative}" unless index.include?("./#{relative}")
end

link_sources = []
Find.find(docs_root.to_s) do |path|
  next unless File.file?(path)
  link_sources << Pathname(path) if %w[.md .html].include?(File.extname(path))
end
Find.find(root.join("design-system").to_s) do |path|
  next unless File.file?(path)
  link_sources << Pathname(path) if %w[.md .html].include?(File.extname(path))
end
%w[README.md AGENTS.md CLAUDE.md SECURITY.md prosepal-ios/README.md supabase/README.md].each do |relative|
  path = root.join(relative)
  link_sources << path if path.file?
end

instruction_sources = []
%w[.claude/commands .agents/skills].each do |relative_root|
  instruction_root = root.join(relative_root)
  next unless instruction_root.directory?

  Find.find(instruction_root.to_s) do |path|
    next unless File.file?(path)
    instruction_sources << Pathname(path) if %w[.md .html].include?(File.extname(path))
  end
end

link_sources.each do |source|
  content = source.read
  targets = content.scan(/\[[^\]]*\]\(([^)]+)\)/).flatten
  targets.concat(content.scan(/(?:href|src)=["']([^"']+)["']/i).flatten)

  targets.each do |raw_target|
    target = raw_target.strip
    target = target[1...-1] if target.start_with?("<") && target.end_with?(">")
    target = target.split(/\s+["']/).first
    next if target.empty? || target.start_with?("#", "//", "/")
    next if target.match?(/\A[a-z][a-z0-9+.-]*:/i)

    target = CGI.unescape(target.split(/[?#]/, 2).first)
    candidate = if target.start_with?("/")
      root.join(target.delete_prefix("/"))
    else
      source.dirname.join(target)
    end.cleanpath

    unless candidate.exist?
      relative_source = source.relative_path_from(root)
      errors << "broken local link in #{relative_source}: #{raw_target}"
    end
  end
end

# Repo-local commands and skills may include upstream reference links whose
# optional reference packs are not vendored here. Validate every link they make
# into this repository without treating those external package-relative links
# as repository documentation.
instruction_sources.each do |source|
  content = source.read
  targets = content.scan(/\[[^\]]*\]\(([^)]+)\)/).flatten
  targets.concat(content.scan(/(?:href|src)=["']([^"']+)["']/i).flatten)

  targets.each do |raw_target|
    target = raw_target.strip
    target = target[1...-1] if target.start_with?("<") && target.end_with?(">")
    target = target.split(/\s+["']/).first
    next unless target.match?(%r{\A(?:docs|prosepal-ios|supabase|scripts|design-system|\.claude|\.agents)/})

    candidate = root.join(CGI.unescape(target.split(/[?#]/, 2).first)).cleanpath
    unless candidate.exist?
      relative_source = source.relative_path_from(root)
      errors << "broken repository link in #{relative_source}: #{raw_target}"
    end
  end
end

active_text_files = []
Find.find(docs_root.to_s) do |path|
  relative = Pathname(path).relative_path_from(docs_root).to_s
  if File.directory?(path)
    Find.prune if relative == "history"
    next
  end
  next if relative == "BACKLOG.md"
  active_text_files << Pathname(path) if %w[.md .html].include?(File.extname(path))
end
active_text_files.concat(%w[README.md AGENTS.md CLAUDE.md SECURITY.md].map { |path| root.join(path) })

path_checked_files = (active_text_files + instruction_sources).uniq

path_checked_files.each do |path|
  next unless path.file?
  path.read.scan(/`([^`\n]+)`/).flatten.each do |token|
    next unless token.match?(%r{\A(?:docs|prosepal-ios|supabase|scripts|design-system|\.claude|\.agents)/})
    next if token.match?(/[\s*<$]/)

    candidate = root.join(token.sub(/:\d+\z/, ""))
    errors << "missing repository path in #{path.relative_path_from(root)}: #{token}" unless candidate.exist?
  end
end

retired_paths = %r{
  docs/(?:NEXT_RELEASE_BRIEF|FEATURES|FEATURE_STATUS|DEVOPS|SERVICE_CONFIG|SERVICE_ENDPOINTS|USER_JOURNEYS|SECURITY|AI_OUTPUT_QUALITY|IOS_RELEASE_CHECKLIST|LAUNCH_CHECKLIST|RELATIONSHIP_ASSISTANT_VISION|PRODUCT_STRATEGY|NATIVE_APP_GUIDE)\.(?:md|csv|html)
  |prosepal-ios/(?:NATIVE_2026_TECHNICAL_DIRECTION|NATIVE_DEVICE_DEBUG_RUNBOOK)\.md
}x

status_phrases = /\b(?:last verified|completion date|current status|candidate backlog|remaining work)\b/i

path_checked_files.each do |path|
  next unless path.file?
  path.each_line.with_index(1) do |line, number|
    relative = path.relative_path_from(root)
    errors << "retired canonical path in #{relative}:#{number}" if line.match?(retired_paths)
    if active_text_files.include?(path)
      errors << "status-report language in active doc #{relative}:#{number}" if line.match?(status_phrases)
    end
  end
end

backlog = docs_root.join("BACKLOG.md")
if backlog.file?
  backlog.each_line.with_index(1) do |line, number|
    errors << "completed checkbox belongs outside the backlog: docs/BACKLOG.md:#{number}" if line.match?(/^\s*-\s*\[[xX]\]/)
  end
end

unless errors.empty?
  warn "Documentation validation failed:"
  errors.uniq.sort.each { |error| warn "- #{error}" }
  exit 1
end

puts "Documentation validation passed (#{active_files.length} active documents indexed; #{link_sources.length} documentation files and #{instruction_sources.length} instruction files checked)."
RUBY
