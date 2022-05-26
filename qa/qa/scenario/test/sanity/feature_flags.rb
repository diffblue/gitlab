# frozen_string_literal: true

module QA
  module Scenario
    module Test
      module Sanity
        class FeatureFlags < Template
          include Bootable

          tags :sanity_feature_flags

          def perform(*args)
            define_gitlab_address(nil, args)

            Runtime::Browser.configure!

            QA::Runtime::Release.perform_before_hooks unless QA::Runtime::Env.dry_run

            Specs::Runner.perform do |specs|
              specs.tty = true
              specs.tags = self.class.focus
              specs.options = args if args.any?
            end
          end
        end
      end
    end
  end
end
