# frozen_string_literal: true

module SemChangelog
  class SemverCalculator
    def normalize_tag(tag)
      return "0.0.0" if tag.nil? || tag.empty?

      clean = tag.delete_prefix("v")
      parts = clean.split(".").map(&:to_i)
      parts << 0 while parts.length < 3
      parts.first(3).join(".")
    end

    def next_version(current_version, commits, force: "auto")
      major, minor, patch = current_version.split(".").map(&:to_i)

      level = case force
              when "major", "minor", "patch"
                force
              else
                detect_bump_level(commits)
              end

      case level
      when "major"
        "#{major + 1}.0.0"
      when "minor"
        "#{major}.#{minor + 1}.0"
      else
        "#{major}.#{minor}.#{patch + 1}"
      end
    end

    private

    def detect_bump_level(commits)
      return "major" if commits.any?(&:breaking)
      return "minor" if commits.any? { |c| c.type == "feat" }

      "patch"
    end
  end
end