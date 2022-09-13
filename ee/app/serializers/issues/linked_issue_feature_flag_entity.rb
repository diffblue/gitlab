# frozen_string_literal: true

module Issues
  class LinkedIssueFeatureFlagEntity < Grape::Entity
    include RequestAwareEntity

    expose :id, :name, :iid

    expose :active

    expose :path do |link|
      edit_project_feature_flag_path(link.project, link.iid)
    end

    expose :reference do |link|
      link.to_reference(issuable.project)
    end

    expose :link_type do |_issue|
      'relates_to'
    end

    def issuable
      request.issuable
    end
  end
end
