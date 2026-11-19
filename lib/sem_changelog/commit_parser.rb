# frozen_string_literal: true

module SemChangelog
  class CommitParser
    ParsedCommit = Struct.new(:type, :scope, :description, :breaking, :sha, keyword_init: true)

    CONVENTIONAL_REGEX = /\A(?<type>[a-zA-Z0-9_-]+)(?:\((?<scope>[^)]+)\))?(?<bang>!)?:\s+(?<desc>.+)\z/

    def parse(commit_data)
      match = CONVENTIONAL_REGEX.match(commit_data.subject)
      breaking_in_body = commit_data.body.match?(/BREAKING CHANGE:/i)

      unless match
        return ParsedCommit.new(
          type: "other",
          scope: nil,
          description: commit_data.subject,
          breaking: breaking_in_body,
          sha: commit_data.sha
        )
      end

      ParsedCommit.new(
        type: match[:type].downcase,
        scope: match[:scope],
        description: match[:desc].strip,
        breaking: !match[:bang].nil? || breaking_in_body,
        sha: commit_data.sha
      )
    end
  end
end