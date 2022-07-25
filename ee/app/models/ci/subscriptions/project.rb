# frozen_string_literal: true

module Ci
  module Subscriptions
    class Project < Ci::ApplicationRecord
      include Ci::NamespacedModelName
      include ::Limitable

      self.table_name = 'ci_subscriptions_projects'

      self.limit_name = 'ci_project_subscriptions'
      self.limit_scope = :upstream_project

      belongs_to :downstream_project, class_name: '::Project', optional: false
      belongs_to :upstream_project, class_name: '::Project', optional: false
      belongs_to :author, class_name: '::User'

      validates :upstream_project_id, uniqueness: { scope: :downstream_project_id }

      validate do
        errors.add(:upstream_project, 'needs to be public') unless upstream_public?
      end

      def self.with_downstream_and_author
        preload(:author, :downstream_project)
      end

      private

      def upstream_public?
        upstream_project&.public?
      end
    end
  end
end
