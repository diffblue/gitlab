# frozen_string_literal: true

module EE
  module Namespaces
    module GroupProjectNamespaceSharedPolicy
      extend ActiveSupport::Concern

      prepended do
        with_scope :subject
        condition(:okrs_enabled) do
          @subject.okrs_mvc_feature_flag_enabled? && @subject.licensed_feature_available?(:okrs)
        end

        rule { can?(:create_work_item) & okrs_enabled }.policy do
          enable :create_objective
          enable :create_key_result
        end
      end
    end
  end
end
