# frozen_string_literal: true

module QualityManagement
  module TestCases
    class CreateService < BaseService
      ISSUE_TYPE = 'test_case'

      def initialize(project, current_user, title:, description: nil, label_ids: [])
        super(project, current_user)

        @title = title
        @description = description
        @label_ids = label_ids
      end

      def execute
        Issues::CreateService.new(
          container: project,
          current_user: current_user,
          params: {
            issue_type: ISSUE_TYPE,
            title: title,
            description: description,
            label_ids: label_ids
          },
          spam_params: nil
        ).execute
      end

      private

      attr_reader :title, :description, :label_ids
    end
  end
end
