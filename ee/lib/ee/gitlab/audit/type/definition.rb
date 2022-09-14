# frozen_string_literal: true

module EE
  module Gitlab
    module Audit
      module Type
        module Definition
          module ClassMethods
            extend ::Gitlab::Utils::Override

            override :paths
            def paths
              @ee_paths ||= [Rails.root.join('ee', 'config', 'audit_events', 'types', '*.yml')] + super
            end
          end

          def self.prepended(base)
            base.singleton_class.prepend ClassMethods
          end
        end
      end
    end
  end
end
