# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::SummarizeComments::Executor, feature_category: :shared do
  let(:input_variables) { { input: "user input", suggestions: "" } }
  let(:tool) { described_class.new(context: context, options: input_variables) }

  describe '#name' do
    it 'returns tool name' do
      expect(described_class::NAME).to eq('SummarizeComments')
    end
  end

  describe '#description' do
    it 'returns tool description' do
      desc = 'This tool is useful when you need to create a summary ' \
             'of all notes, comments or discussions on a given resource.'

      expect(described_class::DESCRIPTION).to include(desc)
    end
  end

  describe '#execute', :saas do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group_with_plan, plan: :ultimate_plan) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:issue1) { create(:issue, project: project) }

    before do
      stub_application_setting(check_namespace_plan: true)
      stub_licensed_features(summarize_notes: true, ai_features: true)

      project.add_developer(user)
      project.root_ancestor.update!(experiment_features_enabled: true, third_party_ai_features_enabled: true)
    end

    context 'when issue is identified' do
      let(:context) do
        Gitlab::Llm::Chain::GitlabContext.new(
          container: project,
          resource: issue1,
          current_user: user,
          ai_request: double
        )
      end

      context 'when user has permission to read resource' do
        context 'when resource has no comments to summarize' do
          it 'responds without making an AI call' do
            expect(tool).not_to receive(:request)

            response = "Issue ##{issue1.iid} has no comments to be summarized."
            expect(tool.execute.content).to eq(response)
          end
        end

        context 'when resource has comments to summarize' do
          let_it_be(:notes) { create_pair(:note_on_issue, project: project, noteable: issue1) }

          context 'when no permissions to use ai features' do
            before do
              stub_licensed_features(summarize_notes: false, ai_features: false)
            end

            it 'responds with error' do
              expect(tool).not_to receive(:request)

              response = "Issue #1: AI features are not enabled or resource is not permitted to be sent."
              expect(tool.execute.content).to eq(response)
            end
          end

          context 'when resource was already summarized' do
            before do
              context.tools_used << described_class.name
            end

            it 'returns already summarized response' do
              expect(tool).not_to receive(:request)

              response = "You already have the summary of the notes, comments, discussions for the " \
                         "Issue ##{issue1.iid} in your context, read carefully."

              expect(tool.execute.content).to include(response)
            end
          end

          it 'responds with summary' do
            expect(tool).not_to receive(:request)

            response = "I know the summary of the notes, comments, discussions for the"
            expect(tool.execute.content).to include(response)
          end
        end
      end
    end

    context 'when resource is not a noteable type' do
      let(:context) do
        Gitlab::Llm::Chain::GitlabContext.new(
          container: project,
          resource: project,
          current_user: user,
          ai_request: double
        )
      end

      it 'responds with error' do
        expect(tool).not_to receive(:request)

        response = "I am sorry, I cannot proceed with this resource, it is Project."
        expect(tool.execute.content).to eq(response)
      end
    end
  end
end
