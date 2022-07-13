# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SearchController, :elastic do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET #show' do
    context 'unique users tracking' do
      before do
        stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
        allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)
      end

      describe 'Snowplow event tracking', :snowplow do
        let(:category) { described_class.to_s }
        let(:namespace) { create(:group) }

        subject { get :show, params: { group_id: namespace.id, scope: 'blobs', search: 'term' } }

        it 'is not sending events if FF is disabled' do
          stub_feature_flags(route_hll_to_snowplow_phase2: false)

          subject

          expect_no_snowplow_event
        end

        it 'emits all search events' do
          subject

          expect_snowplow_event(category: category, action: 'i_search_total', namespace: namespace, user: user)
          expect_snowplow_event(category: category, action: 'i_search_paid', namespace: namespace, user: user)
          expect_snowplow_event(category: category, action: 'i_search_advanced', namespace: namespace, user: user)
        end
      end

      context 'i_search_advanced', :snowplow do
        let_it_be(:group) { create(:group) }

        let(:target_event) { 'i_search_advanced' }

        subject(:request) { get :show, params: { group_id: group.id, scope: 'projects', search: 'term' } }

        it_behaves_like 'tracking unique hll events' do
          let(:expected_value) { instance_of(String) }
        end
      end

      context 'i_search_paid' do
        let_it_be(:group) { create(:group) }

        let(:request_params) { { group_id: group.id, scope: 'blobs', search: 'term' } }
        let(:target_event) { 'i_search_paid' }

        context 'on Gitlab.com', :snowplow do
          subject(:request) { get :show, params: request_params }

          before do
            allow(::Gitlab).to receive(:com?).and_return(true)
            stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
          end

          it_behaves_like 'tracking unique hll events' do
            let(:expected_value) { instance_of(String) }
          end
        end

        context 'self-managed instance' do
          before do
            allow(::Gitlab).to receive(:com?).and_return(false)
          end

          context 'license is available' do
            before do
              stub_licensed_features(elastic_search: true)
            end

            it_behaves_like 'tracking unique hll events' do
              subject(:request) { get :show, params: request_params }

              let(:expected_value) { instance_of(String) }
            end
          end

          it 'does not track if there is no license available' do
            stub_licensed_features(elastic_search: false)
            expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event).with(target_event, values: instance_of(String))

            get :show, params: request_params, format: :html
          end
        end
      end
    end

    shared_examples 'renders the elasticsearch tabs if elasticsearch is enabled' do
      using RSpec::Parameterized::TableSyntax

      render_views

      subject { get :show, params: request_params, format: :html }

      where(:scope) { %w[projects issues merge_requests milestones epics notes blobs commits wiki_blobs users] }

      with_them do
        context 'when elasticsearch is enabled' do
          before do
            stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
          end

          it 'shows the elasticsearch tabs' do
            subject

            expect(response.body).to have_link('Code')
            expect(response.body).to have_link('Wiki')
            expect(response.body).to have_link('Comments')
            expect(response.body).to have_link('Commits')
          end
        end

        context 'when elasticsearch is disabled' do
          before do
            stub_ee_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
          end

          it 'does not show the elasticsearch tabs' do
            subject

            expect(response.body).not_to have_link('Code')
            expect(response.body).not_to have_link('Wiki')
            expect(response.body).not_to have_link('Comments')
            expect(response.body).not_to have_link('Commits')
          end
        end
      end
    end

    shared_examples 'search tabs displayed in consistent order' do
      render_views

      let(:scope) { 'issues' }

      subject { get :show, params: request_params, format: :html }

      it 'keeps search tab order' do
        subject

        # this order should be consistent across global, group, and project scoped searches
        # though all tabs may not be available depending on the search scope and features enabled (epics, advanced search)
        global_expected_order = %w[projects blobs epics issues merge_requests wiki_blobs commits notes milestones users]
        tabs = response.body.scan(/search\?.*scope=(\w*)&amp/).flatten
        expect(tabs).to eq(global_expected_order & tabs)
      end
    end

    context 'global search' do
      let(:request_params) { { scope: scope, search: 'term' } }

      it_behaves_like 'renders the elasticsearch tabs if elasticsearch is enabled'

      context 'scope tab order' do
        context 'when elasticsearch is disabled' do
          before do
            stub_ee_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
          end

          it_behaves_like 'search tabs displayed in consistent order'
        end

        context 'when elasticsearch is enabled' do
          before do
            stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
          end

          it_behaves_like 'search tabs displayed in consistent order'
        end
      end
    end

    context 'group search' do
      let_it_be(:group) { create(:group) }

      let(:request_params) { { group_id: group.id, scope: scope, search: 'term' } }

      it_behaves_like 'renders the elasticsearch tabs if elasticsearch is enabled'

      context 'scope tab order' do
        context 'when elasticsearch is disabled' do
          before do
            stub_ee_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
          end

          context 'when epics are disabled' do
            before do
              stub_licensed_features(epics: false)
            end

            it_behaves_like 'search tabs displayed in consistent order'
          end

          context 'when epics are enabled' do
            before do
              stub_licensed_features(epics: true)
            end

            it_behaves_like 'search tabs displayed in consistent order'
          end
        end

        context 'when elasticsearch is enabled' do
          before do
            stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
          end

          context 'when epics are disabled' do
            before do
              stub_licensed_features(epics: false)
            end

            it_behaves_like 'search tabs displayed in consistent order'
          end

          context 'when epics are enabled' do
            before do
              stub_licensed_features(epics: true)
            end

            it_behaves_like 'search tabs displayed in consistent order'
          end
        end
      end
    end

    context 'project search' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, group: group) }

      let(:request_params) { { project_id: project.id, group_id: project.group, scope: scope, search: 'term' } }

      before do
        project.add_developer(user)
      end

      context 'scope tab order' do
        context 'when elasticsearch is disabled' do
          before do
            stub_ee_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
          end

          it_behaves_like 'search tabs displayed in consistent order'
        end

        context 'when elasticsearch is enabled' do
          before do
            stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
          end

          it_behaves_like 'search tabs displayed in consistent order'
        end
      end
    end
  end

  describe '#append_info_to_payload' do
    before do
      allow_next_instance_of(SearchService) do |service|
        allow(service).to receive(:use_elasticsearch?).and_return use_elasticsearch
      end
    end

    context 'when using elasticsearch' do
      let(:use_elasticsearch) { true }

      it 'appends the type of search used as advanced' do
        expect(controller).to receive(:append_info_to_payload).and_wrap_original do |method, payload|
          method.call(payload)

          expect(payload[:metadata]['meta.search.type']).to eq('advanced')
        end

        get :show, params: { search: 'hello world' }
      end
    end

    context 'when using basic search' do
      let(:use_elasticsearch) { false }

      it 'appends the type of search used as basic' do
        expect(controller).to receive(:append_info_to_payload).and_wrap_original do |method, payload|
          method.call(payload)

          expect(payload[:metadata]['meta.search.type']).to eq('basic')
        end

        get :show, params: { search: 'hello world', basic_search: true }
      end
    end
  end
end
