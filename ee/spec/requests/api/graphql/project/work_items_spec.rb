# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a work item list for a project', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:current_user) { create(:user) }

  let(:items_data) { graphql_data['project']['workItems']['edges'] }
  let(:item_ids) { graphql_dig_at(items_data, :node, :id) }
  let(:item_filter_params) { {} }

  let(:fields) do
    <<~QUERY
    edges {
      node {
        #{all_graphql_fields_for('workItems'.classify)}
      }
    }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('workItems', item_filter_params, fields)
    )
  end

  describe 'work items with widgets' do
    let(:widgets_data) { graphql_dig_at(items_data, :node, :widgets) }

    context 'with status widget' do
      let_it_be(:work_item1) { create(:work_item, :satisfied_status, project: project) }
      let_it_be(:work_item2) { create(:work_item, :failed_status, project: project) }
      let_it_be(:work_item3) { create(:work_item, :requirement, project: project) }

      let(:fields) do
        <<~QUERY
        edges {
          node {
            id
            widgets {
              type
              ... on WorkItemWidgetStatus {
                status
              }
            }
          }
        }
        QUERY
      end

      before do
        stub_licensed_features(requirements: true, okrs: true)
      end

      it 'returns work items including status', :aggregate_failures do
        post_graphql(query, current_user: current_user)

        expect(item_ids).to contain_exactly(
          work_item1.to_global_id.to_s,
          work_item2.to_global_id.to_s,
          work_item3.to_global_id.to_s
        )
        expect(widgets_data).to include(
          a_hash_including('status' => 'satisfied'),
          a_hash_including('status' => 'failed'),
          a_hash_including('status' => 'unverified')
        )
      end

      it 'avoids N+1 queries', :use_sql_query_cache do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          post_graphql(query, current_user: current_user)
        end

        create_list(:work_item, 3, :satisfied_status, project: project)

        expect { post_graphql(query, current_user: current_user) }.not_to exceed_all_query_limit(control)
      end

      context 'when filtering' do
        context 'with status widget' do
          let(:item_filter_params) { 'statusWidget: { status: FAILED }' }

          it 'filters by status argument' do
            post_graphql(query, current_user: current_user)

            expect(response).to have_gitlab_http_status(:success)
            expect(item_ids).to contain_exactly(work_item2.to_global_id.to_s)
          end
        end
      end
    end

    context 'with legacy requirement widget' do
      let_it_be(:work_item1) { create(:work_item, :requirement, project: project) }
      let_it_be(:work_item2) { create(:work_item, :requirement, project: project) }
      let_it_be(:work_item3) { create(:work_item, :requirement, project: project) }
      let_it_be(:work_item3_different_project) { create(:work_item, :requirement, iid: work_item3.iid) }

      let(:fields) do
        <<~QUERY
        edges {
          node {
            id
            widgets {
              type
              ... on WorkItemWidgetRequirementLegacy {
                legacyIid
              }
            }
          }
        }
        QUERY
      end

      before do
        stub_licensed_features(requirements: true)
      end

      it 'returns work items including legacy iid', :aggregate_failures do
        post_graphql(query, current_user: current_user)

        expect(item_ids).to contain_exactly(
          work_item1.to_global_id.to_s,
          work_item2.to_global_id.to_s,
          work_item3.to_global_id.to_s
        )

        expect(widgets_data).to include(
          a_hash_including('legacyIid' => work_item1.requirement.iid),
          a_hash_including('legacyIid' => work_item2.requirement.iid),
          a_hash_including('legacyIid' => work_item3.requirement.iid)
        )
      end

      it 'avoids N+1 queries', :use_sql_query_cache do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          post_graphql(query, current_user: current_user)
        end

        create_list(:work_item, 3, :requirement, project: project)

        expect { post_graphql(query, current_user: current_user) }.not_to exceed_all_query_limit(control)
      end

      context 'when filtering' do
        context 'with legacy requirement widget' do
          let(:item_filter_params) { "requirementLegacyWidget: { legacyIids: [\"#{work_item2.requirement.iid}\"] }" }

          it 'filters by legacy IID argument' do
            post_graphql(query, current_user: current_user)

            expect(response).to have_gitlab_http_status(:success)
            expect(item_ids).to contain_exactly(work_item2.to_global_id.to_s)
          end
        end
      end
    end

    describe 'fetching work item notes widget' do
      let(:work_item) { create(:work_item, :issue, project: project) }
      let(:item_filter_params) { { iid: work_item.iid.to_s } }
      let(:fields) do
        <<~GRAPHQL
        edges {
          node {
            widgets {
              type
              ... on WorkItemWidgetNotes {
                system: discussions(filter: ONLY_ACTIVITY, first: 10) { nodes { id  notes { nodes { id system internal body } } } },
                comments: discussions(filter: ONLY_COMMENTS, first: 10) { nodes { id  notes { nodes { id system internal body } } } },
                all_notes: discussions(filter: ALL_NOTES, first: 10) { nodes { id  notes { nodes { id system internal body } } } }
              }
            }
          }
        }
        GRAPHQL
      end

      it 'fetches notes that require gitaly call to parse note' do
        # this 9 digit long weight triggers a gitaly call when parsing the system note
        create(:resource_weight_event, user: current_user, issue: work_item, weight: 123456789)

        post_graphql(query, current_user: current_user)

        expect_graphql_errors_to_be_empty
      end

      context 'when fetching description version diffs' do
        shared_examples 'description change diff' do |description_diffs_enabled: true|
          it 'returns previous description change diff' do
            post_graphql(query, current_user: current_user)

            # check that system note is added
            note = find_note(work_item, 'changed the description') # system note about changed description
            expect(work_item.reload.description).to eq('updated description')
            expect(note.note).to eq('changed the description')

            # check that diff is returned
            all_widgets = graphql_dig_at(items_data, :node, :widgets)
            notes_widget = all_widgets.find { |x| x["type"] == "NOTES" }

            system_notes = graphql_dig_at(notes_widget["system"], :nodes)
            description_changed_note = graphql_dig_at(system_notes.first["notes"], :nodes).first
            description_version = graphql_dig_at(description_changed_note['systemNoteMetadata'], :descriptionVersion)

            id = GitlabSchema.parse_gid(description_version['id'], expected_type: ::DescriptionVersion).model_id
            diff = description_version['diff']
            diff_path = description_version['diffPath']
            delete_path = description_version['deletePath']
            can_delete = description_version['canDelete']
            deleted = description_version['deleted']

            url_helpers = ::Gitlab::Routing.url_helpers
            url_args = [work_item.project, work_item, id]

            if description_diffs_enabled
              expect(diff).to eq("<span class=\"idiff addition\">updated description</span>")
              expect(diff_path).to eq(url_helpers.description_diff_project_issue_path(*url_args))
              expect(delete_path).to eq(url_helpers.delete_description_version_project_issue_path(*url_args))
              expect(can_delete).to be true
            else
              expect(diff).to be_nil
              expect(diff_path).to be_nil
              expect(delete_path).to be_nil
              expect(can_delete).to be_nil
            end

            expect(deleted).to be false
          end
        end

        let(:fields) do
          <<~GRAPHQL
            edges {
              node {
                widgets {
                  type
                  ... on WorkItemWidgetNotes {
                    system: discussions(filter: ONLY_ACTIVITY, first: 10) {
                      nodes {
                        id
                        notes {
                          nodes {
                            id
                            system
                            internal
                            body
                            systemNoteMetadata {
                              id
                              descriptionVersion {
                                id
                                diff(versionId: #{version_gid})
                                diffPath
                                deletePath
                                canDelete
                                deleted
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          GRAPHQL
        end

        let(:version_gid) { "null" }
        let(:opts) { {} }
        let(:spam_params) { double }
        let(:widget_params) { { description_widget: { description: "updated description" } } }

        let(:service) do
          WorkItems::UpdateService.new(
            container: project,
            current_user: current_user,
            params: opts,
            spam_params: spam_params,
            widget_params: widget_params
          )
        end

        before do
          stub_spam_services
          project.add_developer(current_user)
          service.execute(work_item)
        end

        it_behaves_like 'description change diff'

        context 'with passed description version id' do
          let(:version_gid) { "\"#{work_item.description_versions.first.to_global_id}\"" }

          it_behaves_like 'description change diff'
        end

        context 'with description_diffs disabled' do
          before do
            stub_licensed_features(description_diffs: false)
          end

          it_behaves_like 'description change diff', description_diffs_enabled: false
        end

        context 'with description_diffs enabled through Registration Features' do
          before do
            stub_licensed_features(description_diffs: false)
            stub_application_setting(usage_ping_features_enabled: true)
          end

          it_behaves_like 'description change diff', description_diffs_enabled: true
        end
      end
    end

    def find_note(work_item, starting_with)
      work_item.notes.find do |note|
        break note if note && note.note.start_with?(starting_with)
      end
    end

    context 'with progress widget' do
      let_it_be(:work_item1) { create(:work_item, :objective, project: project) }
      let_it_be(:progress) { create(:progress, work_item: work_item1) }

      let(:fields) do
        <<~QUERY
        edges {
          node {
            id
            widgets {
              type
              ... on WorkItemWidgetProgress {
                progress
              }
            }
          }
        }
        QUERY
      end

      before do
        stub_licensed_features(okrs: true)
      end

      it 'avoids N+1 queries', :use_sql_query_cache do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          post_graphql(query, current_user: current_user)
        end

        create_list(:work_item, 3, :objective, project: project)

        expect { post_graphql(query, current_user: current_user) }.not_to exceed_all_query_limit(control)
      end
    end

    context 'with test reports widget' do
      let_it_be(:requirement_work_item_1) { create(:work_item, :requirement, project: project) }
      let_it_be(:test_report) { create(:test_report, requirement_issue: requirement_work_item_1) }

      let(:fields) do
        <<~GRAPHQL
          edges {
            node {
              id
              widgets {
                type
                ... on WorkItemWidgetTestReports {
                  testReports {
                    nodes {
                      id
                      author {
                        username
                      }
                    }
                  }
                }
              }
            }
          }
        GRAPHQL
      end

      before do
        stub_licensed_features(requirements: true)
      end

      it 'avoids N+1 queries' do
        post_graphql(query, current_user: current_user) # warmup

        control = ActiveRecord::QueryRecorder.new do
          post_graphql(query, current_user: current_user)
        end

        requirement_work_item_2 = create(:work_item, :requirement, project: project)
        create(:test_report, requirement_issue: requirement_work_item_2)

        expect { post_graphql(query, current_user: current_user) }
          .not_to exceed_all_query_limit(control)
      end
    end
  end
end
