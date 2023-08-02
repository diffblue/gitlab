# frozen_string_literal: true

module Gitlab
  module Llm
    module Templates
      class FillInMergeRequestTemplate
        include Gitlab::Utils::StrongMemoize

        def initialize(user, project, params = {})
          @user = user
          @project = project
          @params = params
        end

        def to_prompt
          <<-PROMPT
            You are an AI code assistant that can understand DIFF in Git diff format, TEMPLATE in a Markdown format and can produce Markdown as a result.

            You will be given TITLE, DIFF, and TEMPLATE. Do the following:
            1. Create a merge request description from the given TEMPLATE.
            2. Given the TITLE and DIFF, explain the diff in detail and add it to the section in the description for explaining the DIFF.
            3. For sections with <!-- AI Skip --> placeholder in the description, copy the content from TEMPLATE.
            4. Return the merge request description.

            TITLE: #{params[:title]}

            DIFF:
            #{extracted_diff}

            TEMPLATE:
            #{content}
          PROMPT
        end

        private

        attr_reader :user, :project, :params

        def extracted_diff
          compare = CompareService
            .new(source_project, params[:source_branch])
            .execute(project, params[:target_branch])

          return unless compare

          # Extract only the diff strings and discard everything else
          compare.raw_diffs.to_a.map do |raw_diff|
            # Each diff string starts with information about the lines changed,
            # bracketed by @@. Removing this saves us tokens.
            #
            # Ex: @@ -0,0 +1,58 @@\n+# frozen_string_literal: true\n+\n+module MergeRequests\n+
            raw_diff.diff.sub(Gitlab::Regex.git_diff_prefix, "")
          end.join.truncate_words(2000)
        end

        def content
          # We truncate words of the template content to 600 words so we can
          # ensure that it fits the maxOutputTokens of Vertex AI which is set to
          # 1024 in the client.
          params[:content]&.truncate_words(600)
        end

        def source_project
          return project unless params[:source_project_id]

          source_project = Project.find_by_id(params[:source_project_id])

          return source_project if source_project.present? && user.can?(:create_merge_request_from, source_project)

          project
        end
      end
    end
  end
end
