# frozen_string_literal: true

module Security
  class FindingPresenter < Vulnerabilities::FindingPresenter
    presents ::Security::Finding, as: :finding

    def location_link_with_raw_path
      "#{root_url}#{raw_path}"
    end

    private

    def raw_path
      return '' unless sha.present?
      return '' unless location.present? && location[:file].present?

      return finding_path unless location[:start_line].present?

      path_with_line_numbers(finding_path, location[:start_line], location[:end_line])
    end

    def finding_path
      @finding_path ||= project_raw_path(finding.project, File.join(finding.sha, location[:file])).gsub(%r{^/}, '')
    end

    def root_url
      Gitlab::Routing.url_helpers.root_url
    end
  end
end
