# frozen_string_literal: true

module Gitlab
  module Sitemaps
    class Generator
      class << self
        include Gitlab::Routing

        GITLAB_ORG_NAMESPACE = 'gitlab-org'

        def execute
          unless Gitlab.com?
            return 'The sitemap can only be generated for Gitlab.com'
          end

          file = Sitemaps::SitemapFile.new

          return "The group '#{GITLAB_ORG_NAMESPACE}' was not found" unless gitlab_org_group

          file.add_elements(generic_urls)
          file.add_elements(gitlab_org_group)
          file.add_elements(gitlab_org_subgroups)
          file.add_elements(gitlab_org_projects)

          if file.empty?
            'No urls found to generate the sitemap'
          else
            file
          end
        end

        private

        def generic_urls
          [
            explore_projects_url,
            explore_snippets_url,
            explore_groups_url
          ]
        end

        def gitlab_org_group
          @gitlab_org_group ||= GroupFinder.new(nil).execute(path: GITLAB_ORG_NAMESPACE, parent_id: nil, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        def gitlab_org_subgroups
          GroupsFinder.new(
            nil,
            parent: gitlab_org_group,
            include_parent_descendants: true
          ).execute
        end

        def gitlab_org_projects
          GroupProjectsFinder.new(
            current_user: nil,
            group: gitlab_org_group,
            params: { non_archived: true },
            options: { include_subgroups: true, exclude_shared: true }
          ).execute.include_project_feature.inc_routes
        end
      end
    end
  end
end
