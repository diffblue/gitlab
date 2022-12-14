# frozen_string_literal: true

module EE
  module Gitlab
    module Database
      module GitlabSchema
        extend ActiveSupport::Concern

        EE_DICTIONARY_PATH = 'ee/db/docs'

        class_methods do
          extend ::Gitlab::Utils::Override

          override :dictionary_path_globs
          def dictionary_path_globs
            super + [Rails.root.join(EE_DICTIONARY_PATH, '*.yml')]
          end

          override :view_path_globs
          def view_path_globs
            super + [Rails.root.join(EE_DICTIONARY_PATH, 'views', '*.yml')]
          end
        end
      end
    end
  end
end
