# frozen_string_literal: true

module EE
  module Gitlab
    module Source
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        private

        override :project
        def project
          'gitlab'
        end
      end
    end
  end
end
