# frozen_string_literal: true

module Projects
  module ComplianceStandards
    class AdherenceFinder
      def initialize(group, current_user, params = {})
        @group = group
        @current_user = current_user
        @params = params
      end

      def execute
        return ::Projects::ComplianceStandards::Adherence.none unless allowed?

        items = init_collection
        items = items.for_projects(params[:project_ids]) if params[:project_ids].present?
        items = items.for_check_name(params[:check_name]) if params[:check_name].present?
        items = items.for_standard(params[:standard]) if params[:standard].present?

        items
      end

      private

      attr_reader :group, :current_user, :params

      def allowed?
        return true if params[:skip_authorization].present?

        Ability.allowed?(current_user, :read_group_compliance_dashboard, group)
      end

      def init_collection
        if params[:include_subgroups].present?
          ::Projects::ComplianceStandards::Adherence.for_group_and_its_subgroups(group)
        else
          ::Projects::ComplianceStandards::Adherence.for_group(group)
        end
      end
    end
  end
end
