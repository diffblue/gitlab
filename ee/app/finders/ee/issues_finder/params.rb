# frozen_string_literal: true

module EE
  module IssuesFinder
    module Params
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      VALID_HEALTH_STATUS_PARAMS = [::Issue.health_statuses.keys,
                                    ::IssuableFinder::Params::FILTER_NONE,
                                    ::IssuableFinder::Params::FILTER_ANY].flatten.freeze

      def by_epic?
        params[:epic_id].present?
      end

      def filter_by_no_epic?
        params[:epic_id].to_s.downcase == ::IssuableFinder::Params::FILTER_NONE
      end

      def filter_by_any_epic?
        params[:epic_id].to_s.downcase == ::IssuableFinder::Params::FILTER_ANY
      end

      def weights?
        params[:weight].present? && params[:weight].to_s.casecmp(::Issue::WEIGHT_ALL) != 0
      end

      def filter_by_no_weight?
        params[:weight].to_s.downcase == ::IssuableFinder::Params::FILTER_NONE
      end

      def filter_by_any_weight?
        params[:weight].to_s.downcase == ::IssuableFinder::Params::FILTER_ANY
      end

      def epics
        if params[:include_subepics]
          ::Gitlab::ObjectHierarchy.new(::Epic.id_in(params[:epic_id])).base_and_descendants.select(:id)
        else
          params[:epic_id]
        end
      end

      def by_iteration?
        params[:iteration_id].present? || params[:iteration_title].present?
      end

      def iteration_cadence_id
        params[:iteration_cadence_id]
      end

      def by_iteration_cadence?
        iteration_cadence_id.present?
      end

      def filter_by_no_iteration?
        params[:iteration_id].to_s.downcase == ::IssuableFinder::Params::FILTER_NONE
      end

      def filter_by_any_iteration?
        params[:iteration_id].to_s.downcase == ::IssuableFinder::Params::FILTER_ANY
      end

      def filter_by_current_iteration?
        params[:iteration_id].to_s.casecmp(::Iteration::Predefined::Current.title) == 0
      end

      def filter_by_iteration_title?
        params[:iteration_title].present?
      end

      def by_health_status?
        params[:health_status].present?
      end

      def filter_by_no_health_status?
        params[:health_status].to_s.downcase == ::IssuableFinder::Params::FILTER_NONE
      end

      def filter_by_any_health_status?
        params[:health_status].to_s.downcase == ::IssuableFinder::Params::FILTER_ANY
      end
    end
  end
end
