# frozen_string_literal: true

module EE
  module GroupChildEntity
    extend ActiveSupport::Concern

    prepended do
      # For both group and project
      expose :marked_for_deletion do |instance|
        instance.marked_for_deletion?
      end

      expose :compliance_management_framework, if: lambda { |_instance, _options| compliance_framework_available? }
    end

    private

    def compliance_framework_available?
      return unless project?

      object.licensed_feature_available?(:compliance_framework)
    end
  end
end
