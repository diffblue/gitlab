# frozen_string_literal: true

# Routes have been hardcoded in order to improve performance.
module Gitlab
  module Sitemaps
    class UrlExtractor
      class << self
        include Gitlab::Routing

        def extract(element)
          case element
          when String
            element
          when Group
            extract_from_group(element)
          when Project
            extract_from_project(element)
          end
        end

        def extract_from_group(group)
          full_path = group.full_path

          [
            "#{base_url}#{full_path}",
            "#{base_url}groups/#{full_path}/-/issues",
            "#{base_url}groups/#{full_path}/-/merge_requests",
            "#{base_url}groups/#{full_path}/-/packages",
            "#{base_url}groups/#{full_path}/-/epics"
          ]
        end

        def extract_from_project(project)
          full_path = project.full_path

          [
            "#{base_url}#{full_path}"
          ].tap do |urls|
            urls << "#{base_url}#{full_path}/-/merge_requests" if project.feature_available?(:merge_requests, nil)
            urls << "#{base_url}#{full_path}/-/issues" if project.feature_available?(:issues, nil)
            urls << "#{base_url}#{full_path}/-/snippets" if project.feature_available?(:snippets, nil)
            urls << "#{base_url}#{full_path}/-/wikis/home" if project.feature_available?(:wiki, nil)
          end
        end

        private

        def base_url
          @base_url ||= root_url
        end
      end
    end
  end
end
