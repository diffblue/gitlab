# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      module Vulnerabilities
        class IssueLinksLoader < LazyRelationLoader
          self.model = Vulnerability
          self.association = :issue_links

          def relation(link_type: nil)
            base_relation.by_link_type(link_type)
                         .with_issues
          end
        end
      end
    end
  end
end
