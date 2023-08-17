# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::EpicIdentifier::Executor, feature_category: :shared do
  RSpec.shared_examples 'success response' do
    it 'returns success response' do
      ai_request = double
      allow(ai_request).to receive(:request).and_return(ai_response)
      allow(context).to receive(:ai_request).and_return(ai_request)

      response = "I identified the epic #{identifier}."
      expect(tool.execute.content).to eq(response)
    end
  end

  RSpec.shared_examples 'epic not found response' do
    it 'returns response that epic was not found' do
      allow(tool).to receive(:request).and_return(ai_response)

      response = "I am sorry, I am unable to find the epic you are looking for."
      expect(tool.execute.content).to eq(response)
    end
  end

  describe '#name' do
    it 'returns tool name' do
      expect(described_class::NAME).to eq('EpicIdentifier')
    end
  end

  describe '#description' do
    it 'returns tool description' do
      expect(described_class::DESCRIPTION)
        .to include('Useful tool when you need to identify a specific epic')
    end
  end

  describe '#execute', :saas do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:group) { create(:group_with_plan, plan: :ultimate_plan) }
    # we need project for Gitlab::ReferenceExtractor
    let_it_be(:project) { create(:project, group: group) }

    context 'when epic is identified' do
      let_it_be(:epic1) { create(:epic, group: group) }
      let_it_be(:epic2) { create(:epic, group: group) }
      let(:context) do
        Gitlab::Llm::Chain::GitlabContext.new(
          container: group,
          resource: epic1,
          current_user: user,
          ai_request: double
        )
      end

      let(:tool) { described_class.new(context: context, options: input_variables) }
      let(:input_variables) do
        { input: "user input", suggestions: "Action: EpicIdentifier\nActionInput: #{epic1.iid}" }
      end

      context 'when user does not have permission to read resource' do
        context 'when is epic identified with iid' do
          let(:ai_response) { "{\"ResourceIdentifierType\": \"iid\", \"ResourceIdentifier\": #{epic2.iid}}" }

          it_behaves_like 'epic not found response'
        end

        context 'when is epic identified with reference' do
          let(:ai_response) do
            "{\"ResourceIdentifierType\": \"url\", \"ResourceIdentifier\": #{epic1.to_reference(full: true)}}"
          end

          it_behaves_like 'epic not found response'
        end

        context 'when is epic identified with url' do
          let(:url) { Gitlab::Routing.url_helpers.group_epic_url(group, epic2) }
          let(:ai_response) { "{\"ResourceIdentifierType\": \"url\", \"ResourceIdentifier\": \"#{url}\"}" }

          it_behaves_like 'epic not found response'
        end
      end

      context 'when user has permission to read resource' do
        before do
          stub_application_setting(check_namespace_plan: true)
          stub_licensed_features(summarize_notes: true, ai_features: true, epics: true)
          # rubocop: disable RSpec/BeforeAllRoleAssignment
          group.add_guest(user)
          group.update!(experiment_features_enabled: true, third_party_ai_features_enabled: true)
          # rubocop: enable RSpec/BeforeAllRoleAssignment
        end

        context 'when ai response has invalid JSON' do
          it 'retries the ai call' do
            input_variables = { input: "user input", suggestions: "" }
            tool = described_class.new(context: context, options: input_variables)

            allow(tool).to receive(:request).and_return("random string")
            allow(Gitlab::Json).to receive(:parse).and_raise(JSON::ParserError)

            expect(tool).to receive(:request).exactly(3).times

            response = "I am sorry, I am unable to find the epic you are looking for."
            expect(tool.execute.content).to eq(response)
          end
        end

        context 'when there is a StandardError' do
          it 'returns an error' do
            input_variables = { input: "user input", suggestions: "" }
            tool = described_class.new(context: context, options: input_variables)

            allow(tool).to receive(:request).and_raise(StandardError)

            expect(tool.execute.content).to eq("Unexpected error")
          end
        end

        context 'when epic is the current epic in context' do
          let(:identifier) { 'current' }
          let(:ai_response) { "current\", \"ResourceIdentifier\": \"#{identifier}\"}" }

          it_behaves_like 'success response'
        end

        context 'when epic is identified by iid' do
          let(:identifier) { epic2.iid }
          let(:ai_response) { "iid\", \"ResourceIdentifier\": #{identifier}}" }

          it_behaves_like 'success response'
        end

        context 'when is epic identified with reference' do
          let(:identifier) { epic2.to_reference(full: true) }
          let(:ai_response) do
            "reference\", \"ResourceIdentifier\": \"#{identifier}\"}"
          end

          it_behaves_like 'success response'
        end

        context 'when is epic identified with url' do
          let(:identifier) { Gitlab::Saas.com_url + Gitlab::Routing.url_helpers.group_epic_path(group, epic2) }
          let(:ai_response) { "url\", \"ResourceIdentifier\": \"#{identifier}\"}" }

          it_behaves_like 'success response'
        end

        context 'when context container is a group' do
          before do
            context.container = group
          end

          let(:identifier) { epic2.iid }
          let(:ai_response) { "iid\", \"ResourceIdentifier\": #{identifier}}" }

          it_behaves_like 'success response'
        end

        context 'when context container is nil' do
          before do
            context.container = nil
          end

          context 'when epic is identified by iid' do
            let(:identifier) { epic2.iid }
            let(:ai_response) { "iid\", \"ResourceIdentifier\": #{identifier}}" }

            it_behaves_like 'epic not found response'
          end

          context 'when epic is the current epic in context' do
            let(:identifier) { 'current' }
            let(:ai_response) { "current\", \"ResourceIdentifier\": \"#{identifier}\"}" }

            it_behaves_like 'success response'
          end

          context 'when is epic identified with reference' do
            let(:identifier) { epic2.to_reference(full: true) }
            let(:ai_response) do
              "reference\", \"ResourceIdentifier\": \"#{identifier}\"}"
            end

            it_behaves_like 'success response'
          end

          context 'when is epic identified with not-full reference' do
            let(:identifier) { epic2.to_reference(full: false) }
            let(:ai_response) do
              "reference\", \"ResourceIdentifier\": \"#{identifier}\"}"
            end

            it_behaves_like 'success response'
          end

          context 'when is epic identified with url' do
            let(:identifier) { Gitlab::Saas.com_url + Gitlab::Routing.url_helpers.group_epic_path(group, epic2) }
            let(:ai_response) { "url\", \"ResourceIdentifier\": \"#{identifier}\"}" }

            it_behaves_like 'success response'
          end
        end

        context 'when epic was already identified' do
          let(:resource_iid) { epic1.iid }
          let(:ai_response) { "iid\", \"ResourceIdentifier\": #{epic1.iid}}" }

          before do
            context.tools_used << described_class.name
          end

          it 'returns already identified response' do
            ai_request = double
            allow(ai_request).to receive_message_chain(:complete, :dig, :to_s, :strip).and_return(ai_response)
            allow(context).to receive(:ai_request).and_return(ai_request)

            response = "You already have identified the epic #{context.resource.to_global_id}, read carefully."
            expect(tool.execute.content).to eq(response)
          end
        end
      end
    end
  end
end
