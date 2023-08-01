# frozen_string_literal: true

module EE
  module Ci
    module Bridge
      extend ActiveSupport::Concern

      prepended do
        belongs_to :upstream_pipeline, class_name: "::Ci::Pipeline"

        state_machine :status do
          after_transition any => :pending do |bridge|
            next unless bridge.upstream_project

            bridge.run_after_commit do
              bridge.subscribe_to_upstream!
            end
          end
        end
      end

      def subscribe_to_upstream!
        raise InvalidBridgeTypeError unless upstream_project

        ::Ci::SubscribeBridgeService.new(self.project, self.user).execute(self)
      end

      def inherit_status_from_upstream!
        return false unless upstream_pipeline
        return false if self.status == upstream_pipeline.status

        case upstream_pipeline.status
        when 'running'
          self.run!
        when 'success'
          self.success!
        when 'failed'
          self.drop!
        when 'canceled'
          self.cancel!
        when 'skipped'
          self.skip!
        when 'manual'
          self.manual!
        when 'scheduled'
          self.scheduled!
        else
          false
        end
      end

      def upstream_project
        strong_memoize(:upstream_project) do
          upstream_project_path && ::Project.find_by_full_path(upstream_project_path)
        end
      end

      def upstream_project_path
        strong_memoize(:upstream_project_path) do
          options&.dig(:bridge_needs, :pipeline)
        end
      end

      def playable?
        super && !waiting_for_deployment_approval?
      end
    end
  end
end
