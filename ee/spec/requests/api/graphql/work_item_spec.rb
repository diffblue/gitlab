# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.work_item(id)', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:guest) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:iteration) { create(:iteration, iterations_cadence: create(:iterations_cadence, group: project.group)) }
  # rubocop:disable Layout/LineLength
  let_it_be(:work_item) { create(:work_item, project: project, description: '- List item', weight: 1, iteration: iteration) }
  # rubocop:enable Layout/LineLength
  let(:current_user) { guest }
  let(:work_item_data) { graphql_data['workItem'] }
  let(:work_item_fields) { all_graphql_fields_for('WorkItem') }
  let(:global_id) { work_item.to_gid.to_s }

  let(:query) do
    graphql_query_for('workItem', { 'id' => global_id }, work_item_fields)
  end

  before_all do
    project.add_guest(guest)
    project.add_developer(developer)
  end

  context 'when the user can read the work item' do
    context 'when querying widgets' do
      describe 'iteration widget' do
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetIteration {
                iteration {
                  id
                }
              }
            }
          GRAPHQL
        end

        context 'when iterations feature is licensed' do
          before do
            stub_licensed_features(iterations: true)

            post_graphql(query, current_user: current_user)
          end

          it 'returns widget information' do
            expect(work_item_data).to include(
              'id' => work_item.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'ITERATION',
                  'iteration' => {
                    'id' => work_item.iteration.to_global_id.to_s
                  }
                )
              )
            )
          end
        end

        context 'when iteration feature is unlicensed' do
          before do
            stub_licensed_features(iterations: false)

            post_graphql(query, current_user: current_user)
          end

          it 'returns without iteration' do
            expect(work_item_data['widgets']).not_to include(
              hash_including('type' => 'ITERATION')
            )
          end
        end
      end

      describe 'progress widget' do
        let_it_be(:objective) { create(:work_item, :objective, project: project) }
        let_it_be(:progress) { create(:progress, work_item: objective) }
        let(:global_id) { objective.to_gid.to_s }

        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetProgress {
                progress
                updatedAt
                currentValue
                startValue
                endValue
              }
            }
          GRAPHQL
        end

        context 'when okrs feature is licensed' do
          before do
            stub_licensed_features(okrs: true)

            post_graphql(query, current_user: current_user)
          end

          it 'returns widget information' do
            expect(objective&.work_item_type&.base_type).to match('objective')
            expect(work_item_data).to include(
              'id' => objective.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'PROGRESS',
                  'progress' => objective.progress.progress,
                  'updatedAt' => objective.progress.updated_at&.iso8601,
                  'currentValue' => objective.progress.current_value,
                  'startValue' => objective.progress.start_value,
                  'endValue' => objective.progress.end_value
                )
              )
            )
          end
        end

        context 'when okrs feature is unlicensed' do
          before do
            stub_licensed_features(okrs: false)

            post_graphql(query, current_user: current_user)
          end

          it 'returns without progress' do
            expect(objective&.work_item_type&.base_type).to match('objective')
            expect(work_item_data['widgets']).not_to include(
              hash_including(
                'type' => 'PROGRESS'
              )
            )
          end
        end
      end

      describe 'weight widget' do
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetWeight {
                weight
              }
            }
          GRAPHQL
        end

        context 'when issuable weights is licensed' do
          before do
            stub_licensed_features(issue_weights: true)

            post_graphql(query, current_user: current_user)
          end

          it 'returns widget information' do
            expect(work_item_data).to include(
              'id' => work_item.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'WEIGHT',
                  'weight' => work_item.weight
                )
              )
            )
          end
        end

        context 'when issuable weights is unlicensed' do
          before do
            stub_licensed_features(issue_weights: false)

            post_graphql(query, current_user: current_user)
          end

          it 'returns without weight' do
            expect(work_item_data['widgets']).not_to include(
              hash_including(
                'type' => 'WEIGHT'
              )
            )
          end
        end
      end

      describe 'status widget' do
        let_it_be(:work_item) { create(:work_item, :requirement, project: project) }

        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetStatus {
                status
              }
            }
          GRAPHQL
        end

        context 'when requirements is licensed' do
          before do
            stub_licensed_features(requirements: true)

            post_graphql(query, current_user: current_user)
          end

          shared_examples 'response with status information' do
            it 'returns correct data' do
              expect(work_item_data).to include(
                'id' => work_item.to_gid.to_s,
                'widgets' => include(
                  hash_including(
                    'type' => 'STATUS',
                    'status' => status
                  )
                )
              )
            end
          end

          context 'when latest test report status is satisfied' do
            let_it_be(:test_report) { create(:test_report, requirement_issue: work_item, state: :passed) }

            it_behaves_like 'response with status information' do
              let(:status) { 'satisfied' }
            end
          end

          context 'when latest test report status is failed' do
            let_it_be(:test_report) { create(:test_report, requirement_issue: work_item, state: :failed) }

            it_behaves_like 'response with status information' do
              let(:status) { 'failed' }
            end
          end

          context 'with no test report' do
            it_behaves_like 'response with status information' do
              let(:status) { 'unverified' }
            end
          end
        end

        context 'when requirements is unlicensed' do
          before do
            stub_licensed_features(requirements: false)

            post_graphql(query, current_user: current_user)
          end

          it 'returns no status information' do
            expect(work_item_data['widgets']).not_to include(
              hash_including(
                'type' => 'STATUS'
              )
            )
          end
        end
      end

      describe 'test reports widget' do
        let_it_be(:work_item) { create(:work_item, :requirement, project: project) }

        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetTestReports {
                testReports {
                  nodes {
                    id
                  }
                }
              }
            }
          GRAPHQL
        end

        context 'when requirements is licensed' do
          let_it_be(:test_report1) { create(:test_report, requirement_issue: work_item) }
          let_it_be(:test_report2) { create(:test_report, requirement_issue: work_item) }

          before do
            stub_licensed_features(requirements: true)

            post_graphql(query, current_user: current_user)
          end

          it 'returns correct widget data' do
            expect(work_item_data).to include(
              'id' => work_item.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'TEST_REPORTS',
                  'testReports' => {
                    'nodes' => array_including(
                      { 'id' => test_report1.to_global_id.to_s },
                      { 'id' => test_report2.to_global_id.to_s }
                    )
                  }
                )
              )
            )
          end
        end

        context 'when requirements is not licensed' do
          before do
            post_graphql(query, current_user: current_user)
          end

          it 'returns empty widget data' do
            expect(work_item_data['widgets']).not_to include(
              hash_including(
                'type' => 'TEST_REPORTS'
              )
            )
          end
        end
      end

      describe 'labels widget' do
        let(:labels) { create_list(:label, 2, project: project) }
        let(:work_item) { create(:work_item, project: project, labels: labels) }

        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetLabels {
                allowsScopedLabels
                labels {
                  nodes {
                    id
                    title
                  }
                }
              }
            }
          GRAPHQL
        end

        where(:has_scoped_labels_license) do
          [true, false]
        end

        with_them do
          it 'returns widget information' do
            stub_licensed_features(scoped_labels: has_scoped_labels_license)

            post_graphql(query, current_user: current_user)

            expect(work_item_data).to include(
              'id' => work_item.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'LABELS',
                  'allowsScopedLabels' => has_scoped_labels_license,
                  'labels' => {
                    'nodes' => match_array(
                      labels.map { |a| { 'id' => a.to_gid.to_s, 'title' => a.title } }
                    )
                  }
                )
              )
            )
          end
        end
      end

      describe 'legacy requirement widget' do
        let_it_be(:work_item) { create(:work_item, :requirement, project: project) }

        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetRequirementLegacy {
                type
                legacyIid
              }
            }
          GRAPHQL
        end

        context 'when requirements is licensed' do
          before do
            stub_licensed_features(requirements: true)

            post_graphql(query, current_user: current_user)
          end

          it 'returns correct data' do
            expect(work_item_data).to include(
              'id' => work_item.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'REQUIREMENT_LEGACY',
                  'legacyIid' => work_item.requirement.iid
                )
              )
            )
          end
        end

        context 'when requirements is unlicensed' do
          before do
            stub_licensed_features(requirements: false)

            post_graphql(query, current_user: current_user)
          end

          it 'returns no legacy requirement information' do
            expect(work_item_data['widgets']).not_to include(
              hash_including(
                'type' => 'REQUIREMENT_LEGACY',
                'legacyIid' => work_item.requirement.iid
              )
            )
          end
        end
      end

      describe 'notes widget' do
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetNotes {
                system: discussions(filter: ONLY_ACTIVITY, first: 10) { nodes { id  notes { nodes { id system internal body } } } },
                comments: discussions(filter: ONLY_COMMENTS, first: 10) { nodes { id  notes { nodes { id system internal body } } } },
                all_notes: discussions(filter: ALL_NOTES, first: 10) { nodes { id  notes { nodes { id system internal body } } } }
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
              post_graphql(query, current_user: developer)

              # check that system note is added
              note = find_note(work_item, 'changed the description') # system note about changed description
              expect(work_item.reload.description).to eq('updated description')
              expect(note.note).to eq('changed the description')

              # check that diff is returned
              all_widgets = graphql_dig_at(work_item_data, :widgets)
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

            def find_note(work_item, starting_with)
              work_item.notes.find do |note|
                break note if note && note.note.start_with?(starting_with)
              end
            end
          end

          let_it_be_with_reload(:work_item) { create(:work_item, project: project) }

          let(:work_item_fields) do
            <<~GRAPHQL
              id
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
            GRAPHQL
          end

          let(:version_gid) { "null" }
          let(:opts) { {} }
          let(:widget_params) { { description_widget: { description: "updated description" } } }

          let(:service) do
            WorkItems::UpdateService.new(
              container: project,
              current_user: developer,
              params: opts,
              widget_params: widget_params
            )
          end

          before do
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
    end
  end
end
