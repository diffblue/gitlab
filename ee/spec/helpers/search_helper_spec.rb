# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SearchHelper, feature_category: :global_search do
  describe '#search_filter_input_options' do
    let(:options) { helper.search_filter_input_options(:issues) }

    context 'with multiple issue assignees feature' do
      before do
        stub_licensed_features(multiple_issue_assignees: true)
      end

      it 'allows multiple assignees in project context' do
        @project = create :project

        expect(options[:data][:'multiple-assignees']).to eq('true')
      end

      it 'allows multiple assignees in group context' do
        @group = create :group

        expect(options[:data][:'multiple-assignees']).to eq('true')
      end

      it 'allows multiple assignees in dashboard context' do
        expect(options[:data][:'multiple-assignees']).to eq('true')
      end
    end

    context 'without multiple issue assignees feature' do
      before do
        stub_licensed_features(multiple_issue_assignees: false)
      end

      it 'does not allow multiple assignees in project context' do
        @project = create :project

        expect(options[:data][:'multiple-assignees']).to be(nil)
      end

      it 'does not allow multiple assignees in group context' do
        @group = create :group

        expect(options[:data][:'multiple-assignees']).to be(nil)
      end

      it 'allows multiple assignees in dashboard context' do
        expect(options[:data][:'multiple-assignees']).to eq('true')
      end
    end

    describe 'iterations-endpoint' do
      let_it_be(:group, refind: true) { create(:group) }
      let_it_be(:project_under_group, refind: true) { create(:project, group: group) }

      context 'when iterations are available' do
        before do
          stub_licensed_features(iterations: true)
        end

        it 'includes iteration endpoint in project context' do
          @project = project_under_group

          expect(options[:data]['iterations-endpoint']).to eq(expose_path(api_v4_projects_iterations_path(id: @project.id)))
        end

        it 'includes iteration endpoint in group context' do
          @group = group

          expect(options[:data]['iterations-endpoint']).to eq(expose_path(api_v4_groups_iterations_path(id: @group.id)))
        end

        it 'does not include iterations endpoint for projects under a namespace' do
          @project = create(:project, namespace: create(:namespace))

          expect(options[:data]['iterations-endpoint']).to be(nil)
        end

        it 'does not include iterations endpoint in dashboard context' do
          expect(options[:data]['iterations-endpoint']).to be(nil)
        end
      end

      context 'when iterations are not available' do
        before do
          stub_licensed_features(iterations: false)
        end

        it 'does not include iterations endpoint in project context' do
          @project = project_under_group

          expect(options[:data]['iterations-endpoint']).to be(nil)
        end

        it 'does not include iterations endpoint in group context' do
          @group = group

          expect(options[:data]['iterations-endpoint']).to be(nil)
        end
      end
    end
  end

  describe 'search_autocomplete_opts' do
    context "with a user" do
      let(:user) { create(:user) }

      before do
        allow(self).to receive(:current_user).and_return(user)
      end

      it 'includes the users recently viewed epics' do
        recent_epics = instance_double(::Gitlab::Search::RecentEpics)
        expect(::Gitlab::Search::RecentEpics).to receive(:new).with(user: user).and_return(recent_epics)
        group1 = create(:group, :public, :with_avatar)
        group2 = create(:group, :public)
        epic1 = create(:epic, title: 'epic 1', group: group1)
        epic2 = create(:epic, title: 'epic 2', group: group2)

        expect(recent_epics).to receive(:search).with('the search term').and_return(Epic.id_in_ordered([epic1.id, epic2.id]))

        results = search_autocomplete_opts("the search term")

        expect(results.count).to eq(2)

        expect(results[0]).to include({
          category: 'Recent epics',
          id: epic1.id,
          label: 'epic 1',
          url: Gitlab::Routing.url_helpers.group_epic_path(epic1.group, epic1),
          avatar_url: group1.avatar_url
        })

        expect(results[1]).to include({
          category: 'Recent epics',
          id: epic2.id,
          label: 'epic 2',
          url: Gitlab::Routing.url_helpers.group_epic_path(epic2.group, epic2),
          avatar_url: '' # This group didn't have an avatar so set this to ''
        })
      end

      context 'with the filter parameter is present' do
        it 'filter is set to search' do
          project = create(:project, title: 'hello world')
          project.add_developer(user)

          results = search_autocomplete_opts('hello', filter: 'search')
          expect(results.count).to eq(1)

          expect(results.first).to include({
            category: 'Projects',
            id: project.id,
            label: project.full_name,
            url: Gitlab::Routing.url_helpers.project_path(project)
          })
        end

        it 'filter is set to generic' do
          results = search_autocomplete_opts('setting', filter: 'generic')
          expect(results.count).to eq(1)

          expect(results.first).to include({
            category: 'Settings',
            label: 'User settings',
            url: Gitlab::Routing.url_helpers.profile_path
          })
        end
      end
    end
  end

  describe '#search_entries_info_template' do
    let(:com_value) { true }
    let(:elasticsearch_enabled) { true }
    let(:show_snippets) { true }
    let(:collection) { Kaminari.paginate_array([:foo]).page(1).per(10) }
    let(:user) { create(:user) }
    let(:message) { "Showing %{count} %{scope} for %{term_element}" }
    let(:new_message) { message + " in your personal and project snippets" }

    subject { search_entries_info_template(collection) }

    before do
      @current_user = user

      allow(self).to receive(:current_user).and_return(user)
      allow(search_service).to receive(:show_snippets?).and_return(show_snippets)
      allow(Gitlab).to receive(:com?).and_return(com_value)
      stub_ee_application_setting(search_using_elasticsearch: elasticsearch_enabled)
    end

    shared_examples 'returns old message' do
      it do
        expect(subject).to eq message
      end
    end

    context 'when all requirements are met' do
      it 'returns a custom message' do
        expect(subject).to eq new_message
      end
    end

    context 'when not in Gitlab.com' do
      let(:com_value) { false }

      it_behaves_like 'returns old message'
    end

    context 'when elastic search is not enabled' do
      let(:elasticsearch_enabled) { false }

      it_behaves_like 'returns old message'
    end

    context 'when no user is present' do
      let(:user) { nil }

      it_behaves_like 'returns old message'
    end

    context 'when not searching for snippets' do
      let(:show_snippets) { nil }

      it_behaves_like 'returns old message'
    end
  end

  describe '#highlight_and_truncate_issuable' do
    let(:description) { 'hello world' }
    let(:issue) { create(:issue, description: description) }
    let(:user) { create(:user) }
    let(:search_highlight) { {} }

    before do
      allow(self).to receive(:current_user).and_return(user)
      stub_ee_application_setting(search_using_elasticsearch: true)
    end

    # Elasticsearch returns Elasticsearch::Model::HashWrapper class for the highlighting
    subject { highlight_and_truncate_issuable(issue, 'test', Elasticsearch::Model::HashWrapper.new(search_highlight)) }

    context 'when description is not present' do
      let(:description) { nil }

      it 'does nothing' do
        expect(self).not_to receive(:sanitize)

        subject
      end
    end

    context 'when description present' do
      using RSpec::Parameterized::TableSyntax

      where(:description, :search_highlight, :expected) do
        'test'                                                                 | { 1 => { description: ['gitlabelasticsearch→test←gitlabelasticsearch'] } } | "<span class='gl-text-gray-900 gl-font-weight-bold'>test</span>"
        '<span style="color: blue;">this test should not be blue</span>'       | { 1 => { description: ['<span style="color: blue;">this gitlabelasticsearch→test←gitlabelasticsearch should not be blue</span>'] } } | "this <span class='gl-text-gray-900 gl-font-weight-bold'>test</span> should not be blue"
        '<a href="#" onclick="alert(\'XSS\')">Click Me test</a>'               | { 1 => { description: ['<a href="#" onclick="alert(\'XSS\')">Click Me gitlabelasticsearch→test←gitlabelasticsearch</a>'] } } | "<a href='#'>Click Me <span class='gl-text-gray-900 gl-font-weight-bold'>test</span></a>"
        '<script type="text/javascript">alert(\'Another XSS\');</script> test' | { 1 => { description: ['<script type="text/javascript">alert(\'Another XSS\');</script> gitlabelasticsearch→test←gitlabelasticsearch'] } } | "alert(&apos;Another XSS&apos;); <span class='gl-text-gray-900 gl-font-weight-bold'>test</span>"
        'Lorem test ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. Donec.' | { 1 => { description: ['Lorem gitlabelasticsearch→test←gitlabelasticsearch ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. Donec.'] } } | "Lorem <span class='gl-text-gray-900 gl-font-weight-bold'>test</span> ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Don..."
        '<img src="https://random.foo.com/test.png" width="128" height="128" />some image' | { 1 => { description: ['<img src="https://random.foo.com/gitlabelasticsearch→test←gitlabelasticsearch.png" width="128" height="128" />some image'] } } | 'some image'
        '<h2 data-sourcepos="11:1-11:26" dir="auto"><a id="user-content-additional-information" class="anchor" href="#additional-information" aria-hidden="true"></a>Additional information test:</h2><textarea data-update-url="/freepascal.org/fpc/source/-/issues/6163.json" dir="auto" data-testid="textarea" class="hidden js-task-list-field"></textarea>' | { 1 => { description: ['<h2 data-sourcepos="11:1-11:26" dir="auto"><a id="user-content-additional-information" class="anchor" href="#additional-information" aria-hidden="true"></a>Additional information gitlabelasticsearch→test←gitlabelasticsearch:</h2><textarea data-update-url="/freepascal.org/fpc/source/-/issues/6163.json" dir="auto" data-testid="textarea" class="hidden js-task-list-field"></textarea>'] } } | "<a class='anchor' href='#additional-information'></a>Additional information <span class='gl-text-gray-900 gl-font-weight-bold'>test</span>:"
      end

      with_them do
        before do
          # table syntax doesn't allow use of calculated fields so we must fake issue.id
          # to ensure the test goes down the correct path
          allow(issue).to receive(:id).and_return(1)
        end

        it 'sanitizes, truncates, and highlights the search term' do
          expect(subject).to eq(expected)
        end
      end
    end
  end

  describe '#search_sort_options_json' do
    let(:user) { create(:user) }

    mock_relevant_sort = {
      title: _('Most relevant'),
      sortable: false,
      sortParam: 'relevant'
    }

    mock_created_sort = {
      title: _('Created date'),
      sortable: true,
      sortParam: {
        asc: 'created_asc',
        desc: 'created_desc'
      }
    }

    mock_updated_sort = {
      title: _('Updated date'),
      sortable: true,
      sortParam: {
        asc: 'updated_asc',
        desc: 'updated_desc'
      }
    }

    before do
      allow(self).to receive(:current_user).and_return(user)
    end

    context 'with advanced search enabled' do
      before do
        stub_ee_application_setting(search_using_elasticsearch: true)
      end

      it 'returns the correct data' do
        expect(search_sort_options).to eq([mock_relevant_sort, mock_created_sort, mock_updated_sort])
      end
    end

    context 'with basic search enabled' do
      it 'returns the correct data' do
        expect(search_sort_options).to eq([mock_created_sort, mock_updated_sort])
      end
    end
  end

  describe '.search_navigation' do
    using RSpec::Parameterized::TableSyntax
    let(:user) { build(:user) }
    let(:project) { build(:project) }

    before do
      allow(self).to receive(:current_user).and_return(user)
      allow(self).to receive(:can?).and_return(true)
    end

    context 'for epics' do
      where(:global_project, :show_epics, :condition) do
        nil                 | false      | false
        ref(:project)       | true       | false
        ref(:project)       | false      | false
        nil                 | true       | true
      end

      with_them do
        it 'data item condition is set correctly' do
          @project = global_project
          allow(search_service).to receive(:show_epics?).and_return(show_epics)

          expect(search_navigation[:epics][:condition]).to eq(condition)
        end
      end
    end
  end

  describe '.search_navigation_json with .search_navigation' do
    before do
      allow(self).to receive(:current_user).and_return(build(:user))
      allow(self).to receive(:can?).and_return(true)
      allow(self).to receive(:project_search_tabs?).and_return(true)
      allow(self).to receive(:feature_flag_tab_enabled?).and_return(true)
      allow(self).to receive(:feature_flag_tab_enabled?).and_return(true)
      allow(search_service).to receive(:show_elasticsearch_tabs?).and_return(true)
      allow(search_service).to receive(:show_epics?).and_return(true)
      allow(search_service).to receive(:show_snippets?).and_return(true)
      @project = nil
    end

    it 'test search navigation item order for CE all options enabled' do
      expect(Gitlab::Json.parse(search_navigation_json).keys).to eq(%w[projects blobs epics issues merge_requests wiki_blobs commits notes milestones users snippet_titles])
    end
  end

  describe '.search_filter_link_json' do
    using RSpec::Parameterized::TableSyntax

    context 'with data' do
      where(:scope, :label, :data, :search, :active_scope) do
        "projects"       | "Projects"                | { qa_selector: 'projects_tab' } | nil                  | "projects"
        "snippet_titles" | "Titles and Descriptions" | nil                             | { snippets: "test" } | "code"
        "projects"       | "Projects"                | { qa_selector: 'projects_tab' } | nil                  | "issue"
        "snippet_titles" | "Titles and Descriptions" | nil                             | { snippets: "test" } | "snippet_titles"
      end

      with_them do
        it 'converts correctly' do
          @timeout = false
          @scope = active_scope
          @search_results = double
          dummy_count = 1000
          allow(self).to receive(:search_path).with(any_args).and_return("link test")

          allow(@search_results).to receive(:formatted_count).with(scope).and_return(dummy_count)
          allow(self).to receive(:search_count_path).with(any_args).and_return("test count link")

          current_scope = scope == active_scope

          expected = {
            label: label,
            scope: scope,
            data: data,
            link: "link test",
            active: current_scope
          }

          expected[:count] = dummy_count if current_scope
          expected[:count_link] = "test count link" unless current_scope

          expect(search_filter_link_json(scope, label, data, search)).to eq(expected)
        end
      end
    end
  end

  describe 'show_elasticsearch_tabs' do
    let(:user) { build(:user) }
    let_it_be(:project) { build(:project) }

    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
      allow(self).to receive(:current_user).and_return(user)
      allow(self).to receive(:can?).and_return(false)
      allow(self).to receive(:project_search_tabs?).and_return(false)
      allow(self).to receive(:feature_flag_tab_enabled?).and_return(false)
    end

    it 'show_elasticsearch_tabs? returns true' do
      expect(search_service.show_elasticsearch_tabs?).to eq(true)
    end
  end
end
