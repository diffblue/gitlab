# frozen_string_literal: true

module QualityManagement
  module TestCases
    class CreateService < BaseService
      ISSUE_TYPE = 'test_case'
      PERMITTED_PARAMS = %i[title description label_ids confidential].freeze

      def initialize(project, current_user, params: {})
        super(project, current_user)

        @params = params.dup
      end

      def execute
        Issues::CreateService.new(
          container: project,
          current_user: current_user,
          params: sanitized_params.merge(issue_type: ISSUE_TYPE),
          perform_spam_check: false
        ).execute
      end

      private

      attr_reader :params

      def sanitized_params
        params.slice(*PERMITTED_PARAMS)
      end
    end
  end
end
