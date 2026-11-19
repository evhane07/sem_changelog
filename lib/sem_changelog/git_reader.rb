# frozen_string_literal: true

module SemChangelog
  class GitReader
    CommitData = Struct.new(:sha, :subject, :body, keyword_init: true)

    def initialize(repo_path)
      @repo = Rugged::Repository.discover(repo_path)
    end

    def latest_tag
      tags = @repo.tags.map(&:name)
      return nil if tags.empty?

      tags.max_by do |tag|
        Gem::Version.new(tag.delete_prefix("v"))
      rescue ArgumentError
        Gem::Version.new("0.0.0")
      end
    end

    def commits_since(ref)
      head_oid = @repo.head.target_id
      walker = Rugged::Walker.new(@repo)
      walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
      walker.push(head_oid)

      target_oid = nil
      if ref
        target = @repo.rev_parse(ref)
        target_oid = target.respond_to?(:target_id) ? target.target_id : target.oid
        walker.hide(target_oid)
      end

      commits = []
      walker.each do |commit|
        next if target_oid && commit.oid == target_oid

        lines = commit.message.lines
        subject = (lines.first || "").strip
        body = lines.drop(1).join.strip
        commits << CommitData.new(sha: commit.oid[0, 7], subject: subject, body: body)
      end
      commits.reverse
    end
  end
end