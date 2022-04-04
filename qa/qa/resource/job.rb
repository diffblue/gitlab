# frozen_string_literal: true

module QA
  module Resource
    class Job < Base
      attr_writer :id, :project

      def initialize(id, project)
        @id = id
        @project = project
      end

      def fabricate!
      end

      def artifacts
        parse_body(api_get_from(api_get_path))
      end

      def api_get_path
        "/projects/#{project.id}/jobs/#{id}"
      end
    end
  end
end
