# frozen_string_literal: true

module EE
  module Gitlab
    module AuthLogger
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :file_name_noext
        def file_name_noext
          'auth_json'
        end
      end
    end
  end
end
