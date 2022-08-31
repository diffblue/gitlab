# frozen_string_literal: true

module Vulnerabilities
  class FindingPresenter < Gitlab::View::Presenter::Delegated
    presents ::Vulnerabilities::Finding, as: :finding

    def title
      name
    end

    def blob_path
      return '' unless sha.present?
      return '' unless location.present? && location['file'].present?

      add_line_numbers(location['start_line'], location['end_line'])
    end

    delegator_override :links
    def links
      @links ||= finding.links.map(&:with_indifferent_access)
    end

    private

    def add_line_numbers(start_line, end_line)
      return vulnerability_path unless start_line

      path_with_line_numbers(vulnerability_path, start_line, end_line)
    end

    def vulnerability_path
      @vulnerability_path ||= project_blob_path(project, File.join(sha, location['file']))
    end
  end
end
