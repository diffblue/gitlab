# frozen_string_literal: true

module EE
  module ProjectSetting
    extend ActiveSupport::Concern

    prepended do
      belongs_to :push_rule

      scope :has_vulnerabilities, -> { where('has_vulnerabilities IS TRUE') }

      validates :mirror_branch_regex, absence: true, if: -> { project&.only_mirror_protected_branches? }
      validates :mirror_branch_regex, untrusted_regexp: true, length: { maximum: 255 }
      validates :product_analytics_instrumentation_key, length: { maximum: 255 }, allow_blank: true

      validates :jitsu_host,
        length: { maximum: 255 },
        addressable_url: { schemes: %w[http https], allow_localhost: true, allow_local_network: true },
        allow_blank: true
      validates :jitsu_project_xid, length: { maximum: 255 }
      validates :jitsu_administrator_email, length: { maximum: 255 }
      validates :product_analytics_data_collector_host, length: { maximum: 255 }
      validates :cube_api_base_url,
        length: { maximum: 512 },
        addressable_url: { schemes: %w[http https], allow_localhost: true, allow_local_network: true },
        allow_blank: true
    end

    def selective_code_owner_removals
      project.licensed_feature_available?(:merge_request_approvers) &&
        ComplianceManagement::MergeRequestApprovalSettings::Resolver
        .new(project.group, project: project)
        .selective_code_owner_removals
        .value
    end
  end
end
