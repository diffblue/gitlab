# frozen_string_literal: true

module Dora
  module BaseMetric
    class << self
      def for(metric_key)
        all_metric_classes.detect { |klass| klass::METRIC_NAME == metric_key } || raise(ArgumentError, 'Unknown metric')
      end

      def all_metric_classes
        [DeploymentFrequencyMetric, LeadTimeForChangesMetric, TimeToRestoreServiceMetric, ChangeFailureRateMetric]
      end
    end

    def initialize(environment, date)
      @environment = environment
      @date = date
    end

    # Hash map of columns and queries to calculate data for those columns to store in daily metrics later on.
    def data_queries
      raise NoMethodError, "method `data_queries` must be overloaded for #{self.class.name}"
    end

    private

    attr_reader :environment, :date

    def eligible_deployments
      deployments = Deployment.arel_table

      [deployments[:environment_id].eq(environment.id),
       deployments[:finished_at].gteq(date.beginning_of_day),
       deployments[:finished_at].lteq(date.end_of_day),
       deployments[:status].eq(Deployment.statuses[:success])].reduce(&:and)
    end
  end
end
