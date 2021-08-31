# frozen_string_literal: true
module EE
  module Gitlab
    module Ci
      module Parsers
        module Security
          module Validators
            module SchemaValidator
              module Schema
                extend ::Gitlab::Utils::Override

                CE_TYPES = %i(sast secret_detection).freeze

                override :root_path
                def root_path
                  return super if CE_TYPES.include?(report_type)

                  File.join(__dir__, 'schemas')
                end
              end
            end
          end
        end
      end
    end
  end
end
