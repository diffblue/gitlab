# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::IssueIdentifier, feature_category: :shared do
  RSpec.shared_examples 'success response' do
    it 'returns success response' do
      ai_client = double
      allow(ai_client).to receive_message_chain(:complete, :dig, :to_s, :strip).and_return(ai_response)
      allow(context).to receive(:ai_client).and_return(ai_client)

      response = "I now have the JSON information about the issue ##{resource_iid}."
      expect(tool.execute.content).to eq(response)
    end
  end

  RSpec.shared_examples 'issue not found response' do
    it 'returns success response' do
      allow(tool).to receive(:request).and_return(ai_response)

      response = "I am sorry, I am unable to find the issue you are looking for."
      expect(tool.execute.content).to eq(response)
    end
  end

  describe '#name' do
    it 'returns tool name' do
      expect(described_class::NAME).to eq('IssueIdentifier')
    end
  end

  describe '#description' do
    it 'returns tool description' do
      expect(described_class::DESCRIPTION)
        .to include('Useful tool for when you need to identify and fetch information')
    end
  end

  describe '#execute' do
    context 'when ai response has invalid JSON' do
      it 'retries the ai call' do
        input_variables = { input: "user input", suggestions: "" }
        tool = described_class.new(context: double, options: input_variables)

        allow(tool).to receive(:request).and_return("random string")
        allow(Gitlab::Json).to receive(:parse).and_raise(JSON::ParserError)

        expect(tool).to receive(:request).exactly(3).times

        response = "I am sorry, I am unable to find the issue you are looking for."
        expect(tool.execute.content).to eq(response)
      end
    end

    context 'when there is a StandardError' do
      it 'returns an error' do
        input_variables = { input: "user input", suggestions: "" }
        tool = described_class.new(context: double, options: input_variables)

        allow(tool).to receive(:request).and_raise(StandardError)

        expect(tool.execute.content).to eq("Unexpected error")
      end
    end

    context 'when issue is identified' do
      let_it_be(:user) { create(:user) }
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, group: group) }
      let_it_be(:issue1) { create(:issue, project: project) }
      let_it_be(:issue2) { create(:issue, project: project) }
      let(:context) do
        Gitlab::Llm::Chain::GitlabContext.new(
          container: project,
          resource: issue1,
          current_user: user,
          ai_client: double
        )
      end

      let(:tool) { described_class.new(context: context, options: input_variables) }
      let(:input_variables) do
        { input: "user input", suggestions: "Action: IssueIdentifier\nActionInput: #{issue1.iid}" }
      end

      context 'when user does not have permission to read resource' do
        context 'when is issue identified with iid' do
          let(:ai_response) { "{\"ResourceIdentifierType\": \"iid\", \"ResourceIdentifier\": #{issue2.iid}}" }

          it_behaves_like 'issue not found response'
        end

        context 'when is issue identified with reference' do
          let(:ai_response) do
            "{\"ResourceIdentifierType\": \"url\", \"ResourceIdentifier\": #{issue2.to_reference(full: true)}}"
          end

          it_behaves_like 'issue not found response'
        end

        context 'when is issue identified with url' do
          let(:url) { Gitlab::Routing.url_helpers.project_issue_url(project, issue2) }
          let(:ai_response) do
            "{\"ResourceIdentifierType\": \"url\", \"ResourceIdentifier\": #{url}}"
          end

          it_behaves_like 'issue not found response'
        end
      end

      context 'when user has permission to read resource' do
        before do
          project.add_guest(user)
        end

        context 'when issue is the current issue in context' do
          let(:resource_iid) { issue1.iid }
          let(:ai_response) { "{\"ResourceIdentifierType\": \"current\", \"ResourceIdentifier\": \"current\"}" }

          it_behaves_like 'success response'
        end

        context 'when issue is identified by iid' do
          let(:resource_iid) { issue2.iid }
          let(:ai_response) { "{\"ResourceIdentifierType\": \"iid\", \"ResourceIdentifier\": #{issue2.iid}}" }

          it_behaves_like 'success response'
        end

        context 'when is issue identified with reference' do
          let(:resource_iid) { issue2.iid }
          let(:ai_response) do
            "{\"ResourceIdentifierType\": \"url\", \"ResourceIdentifier\": \"#{issue2.to_reference(full: true)}\"}"
          end

          it_behaves_like 'success response'
        end

        context 'when is issue identified with url' do
          let(:resource_iid) { issue2.iid }
          let(:url) { Gitlab::Routing.url_helpers.project_issue_url(project, issue2) }
          let(:ai_response) do
            "{\"ResourceIdentifierType\": \"reference\", \"ResourceIdentifier\": \"#{url}\"}"
          end

          it_behaves_like 'success response'
        end

        context 'when issue mistaken with an MR' do
          let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

          let(:ai_response) { "{\"ResourceIdentifierType\": \"current\", \"ResourceIdentifier\": \"current\"}" }

          before do
            context.resource = merge_request
          end

          it_behaves_like 'issue not found response'
        end

        context 'when context container is a group' do
          before do
            context.container = group
          end

          let(:resource_iid) { issue2.iid }
          let(:ai_response) { "{\"ResourceIdentifierType\": \"iid\", \"ResourceIdentifier\": #{issue2.iid}}" }

          it_behaves_like 'success response'

          context 'when multiple issues are identified' do
            let_it_be(:project) { create(:project, group: group) }
            let_it_be(:issue3) { create(:issue, iid: issue2.iid, project: project) }

            let(:resource_iid) { issue2.iid }
            let(:ai_response) { "{\"ResourceIdentifierType\": \"iid\", \"ResourceIdentifier\": #{issue2.iid}}" }

            it_behaves_like 'issue not found response'
          end
        end

        context 'when context container is a project namespace' do
          before do
            context.container = project.project_namespace
          end

          context 'when issue is the current issue in context' do
            let(:resource_iid) { issue2.iid }
            let(:ai_response) { "{\"ResourceIdentifierType\": \"iid\", \"ResourceIdentifier\": #{issue2.iid}}" }

            it_behaves_like 'success response'
          end
        end

        context 'when issue was already identified' do
          let(:resource_iid) { issue1.iid }
          let(:ai_response) { "{\"ResourceIdentifierType\": \"iid\", \"ResourceIdentifier\": #{issue1.iid}}" }

          before do
            input_variables[:suggestions] = "Action: IssueIdentifier\nActionInput: #{issue1.iid}"
            input_variables[:suggestions] += "Observation: I now have the JSON information about the issue #1"
            input_variables[:suggestions] += "Action: IssueIdentifier\nActionInput: #{issue1.iid}"
          end

          it 'returns already identified response' do
            ai_client = double
            allow(ai_client).to receive_message_chain(:complete, :dig, :to_s, :strip).and_return(ai_response)
            allow(context).to receive(:ai_client).and_return(ai_client)

            response = "You already have identified the issue ##{context.resource.iid}, read carefully."
            expect(tool.execute.content).to eq(response)
          end
        end
      end
    end
  end
end
