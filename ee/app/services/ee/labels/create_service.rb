# frozen_string_literal: true

module EE
  module Labels
    module CreateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(target_params)
        label = super

        if label.respond_to?(:group) && label.persisted? && label.scoped_label?
          Onboarding::ProgressService.new(label.group).execute(action: :scoped_label_created)
        end

        label
      end
    end
  end
end
