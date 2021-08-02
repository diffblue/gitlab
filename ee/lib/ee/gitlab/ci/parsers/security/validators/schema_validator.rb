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
                override :root_path
                def root_path
                  if [:sast, :secret_detection].include?(report_type)
                    super
                  else
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
end
