# frozen_string_literal: true

module CrossModificationTransactionMixin
  extend ActiveSupport::Concern

  class_methods do
    def transaction(**options, &block)
      # default value of joinable is true
      joinable = options[:joinable].nil? || options[:joinable]

      # HACK prepend_comment to get spec/lib/gitlab/database/transaction/observer_spec.rb to pass
      marginalia_prepended = Marginalia::Comment.prepend_comment

      if gitlab_schema && !marginalia_prepended && joinable
        Marginalia.with_annotation("gitlab_schema: #{gitlab_schema}") do
          super(**options, &block)
        end
      else
        super(**options, &block)
      end
    end

    def gitlab_schema
      case self.name
      when 'ActiveRecord::Base', 'ApplicationRecord'
        :gitlab_main
      when 'Ci::ApplicationRecord'
        :gitlab_ci
      else
        Gitlab::Database::GitlabSchema.table_schema(table_name) if table_name
      end
    end
  end
end

ActiveRecord::Base.prepend(CrossModificationTransactionMixin) if Rails.env.test?
