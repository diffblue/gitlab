# frozen_string_literal: true
module EE
  module SearchHelper
    extend ::Gitlab::Utils::Override

    SWITCH_TO_BASIC_SEARCHABLE_TABS = %w[projects issues merge_requests milestones users epics].freeze
    PLACEHOLDER = '_PLACEHOLDER_'

    override :search_filter_input_options
    def search_filter_input_options(type, placeholder = _('Search or filter results...'))
      options = super
      options[:data][:'multiple-assignees'] = 'true' if search_multiple_assignees?(type)

      if @project&.group
        options[:data]['epics-endpoint'] = group_epics_path(@project.group)
      elsif @group.present?
        options[:data]['epics-endpoint'] = group_epics_path(@group)
      end

      if allow_filtering_by_iteration?
        if @project
          options[:data]['iterations-endpoint'] = expose_path(api_v4_projects_iterations_path(id: @project.id))
        elsif @group
          options[:data]['iterations-endpoint'] = expose_path(api_v4_groups_iterations_path(id: @group.id))
        end
      end

      options
    end

    override :recent_items_autocomplete
    def recent_items_autocomplete(term)
      super + recent_epics_autocomplete(term)
    end

    override :search_blob_title
    def search_blob_title(project, path)
      if @project
        path
      else
        (project.full_name + ': ' + content_tag(:i, path)).html_safe
      end
    end

    override :search_entries_scope_label
    def search_entries_scope_label(scope, count)
      case scope
      when 'epics'
        ns_('SearchResults|epic', 'SearchResults|epics', count)
      else
        super
      end
    end

    # This is a special case for snippet searches in .com.
    # The scope used to gather the snippets is too wide and
    # we have to process a lot of them, what leads to time outs.
    # We're reducing the scope only in .com because the current
    # one is still valid in smaller installations.
    # https://gitlab.com/gitlab-org/gitlab/issues/26123
    override :search_entries_info_template
    def search_entries_info_template(collection)
      return super unless gitlab_com_snippet_db_search?

      if collection.total_pages > 1
        s_("SearchResults|Showing %{from} - %{to} of %{count} %{scope} for %{term_element} in your personal and project snippets").html_safe
      else
        s_("SearchResults|Showing %{count} %{scope} for %{term_element} in your personal and project snippets").html_safe
      end
    end

    override :highlight_and_truncate_issuable
    def highlight_and_truncate_issuable(issuable, search_term, search_highlight)
      return super unless search_service.use_elasticsearch? && search_highlight[issuable.id]&.description.present?

      # We use Elasticsearch highlighting for results from Elasticsearch. Sanitize the description, replace the
      # pre/post tags from Elasticsearch with highlighting, truncate, and mark as html_safe. HTML tags are not
      # counted towards the character limit.
      text = search_sanitize(search_highlight[issuable.id].description.first)
      text.gsub!(::Elastic::Latest::GitClassProxy::HIGHLIGHT_START_TAG, '<span class="gl-text-gray-900 gl-font-weight-bold">')
      text.gsub!(::Elastic::Latest::GitClassProxy::HIGHLIGHT_END_TAG, '</span>')
      search_truncate(text).html_safe
    end

    def advanced_search_status_marker(project)
      ref = params[:repository_ref]
      enabled = project.nil? || ref.blank? || ref == project.default_branch

      tags = {}
      tags[:doc_link_start], tags[:doc_link_end] = tag.a(
        PLACEHOLDER,
        href: help_page_path('user/search/advanced_search'),
        rel: :noopener,
        target: '_blank'
      ).split(PLACEHOLDER)

      unless enabled
        tags[:ref_elem] = tag.a(href: '#', class: 'ref-truncated has-tooltip', data: { title: ref }) do
          tag.code(ref, class: 'gl-white-space-nowrap')
        end

        tags[:default_branch] = tag.code(project.default_branch)

        tags[:default_branch_link_start], tags[:default_branch_link_end] = link_to(
          PLACEHOLDER,
          search_path(safe_params.except(:repository_ref)),
          data: { testid: 'es-search-default-branch' }
        ).split(PLACEHOLDER)

        tags[:docs_link] = link_to(
          _('Learn more.'),
          help_page_path('user/search/advanced_search', anchor: 'use-the-advanced-search-syntax'),
          target: '_blank',
          rel: 'noopener noreferrer'
        )
      end

      # making sure all the tags are marked `html_safe`
      message =
        if enabled
          _('%{doc_link_start}Advanced search%{doc_link_end} is enabled.')
        else
          _('%{doc_link_start}Advanced search%{doc_link_end} is disabled since %{ref_elem} is not the default branch. %{docs_link}')
        end % tags.transform_values(&:html_safe)

      # wrap it inside a `div` for testing purposes
      tag.div(message.html_safe, data: { testid: 'es-status-marker', enabled: enabled })
    end

    override :search_sort_options
    def search_sort_options
      original_options = super

      options = []

      if search_service.use_elasticsearch?
        options << {
          title: _('Most relevant'),
          sortable: false,
          sortParam: 'relevant'
        }
      end

      options + original_options
    end

    override :search_navigation
    def search_navigation
      super.merge(epics: { sort: 3, label: _("Epics"), condition: @project.nil? && search_service.show_epics? })
    end

    override :search_scope
    def search_scope
      if current_controller?(:epics)
        'epics'
      else
        super
      end
    end

    private

    def recent_epics_autocomplete(term)
      return [] unless current_user

      ::Gitlab::Search::RecentEpics.new(user: current_user).search(term).map do |e|
        {
          category: "Recent epics",
          id: e.id,
          label: search_result_sanitize(e.title),
          url: epic_path(e),
          avatar_url: e.group.avatar_url || '',
          group_id: e.group_id,
          group_name: e.group&.name
        }
      end
    end

    def search_multiple_assignees?(type)
      context = @project.presence || @group.presence || :dashboard

      type == :issues && (context == :dashboard ||
        context.feature_available?(:multiple_issue_assignees))
    end

    def allow_filtering_by_iteration?
      # We currently only have group-level iterations so we hide
      # this filter for projects under personal namespaces
      return false if @project && @project.namespace.user_namespace?

      context = @project.presence || @group.presence

      context&.feature_available?(:iterations)
    end

    def gitlab_com_snippet_db_search?
      @current_user &&
        search_service.show_snippets? &&
        ::Gitlab.com? &&
        ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: nil)
    end
  end
end
