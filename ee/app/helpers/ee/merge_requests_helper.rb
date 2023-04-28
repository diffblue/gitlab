# frozen_string_literal: true

module EE
  module MergeRequestsHelper
    extend ::Gitlab::Utils::Override

    def render_items_list(items, separator = "and")
      items_cnt = items.size

      case items_cnt
      when 1
        items.first
      when 2
        "#{items.first} #{separator} #{items.last}"
      else
        last_item = items.pop
        "#{items.join(", ")} #{separator} #{last_item}"
      end
    end

    override :diffs_tab_pane_data
    def diffs_tab_pane_data(project, merge_request, params)
      super.merge(
        endpoint_codequality: (codequality_mr_diff_reports_project_merge_request_path(project, merge_request, 'json') if project.licensed_feature_available?(:inline_codequality) && merge_request.has_codequality_mr_diff_report?),
        show_generate_test_file_button: ::Llm::GenerateTestFileService.new(current_user, merge_request).valid?.to_s
      )
    end
  end
end
