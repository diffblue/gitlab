# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Agents::ZeroShot::Executor, :clean_gitlab_redis_chat, feature_category: :duo_chat do
  include FakeBlobHelpers

  let_it_be(:user) { create(:user) }

  describe 'real requests', :real_ai_request, :saas do
    using RSpec::Parameterized::TableSyntax

    let_it_be_with_reload(:group) { create(:group_with_plan, :public, plan: :ultimate_plan) }
    let_it_be(:project) { create(:project, :repository, group: group) }

    let(:response_service_double) { instance_double(::Gitlab::Llm::ResponseService) }
    let(:resource) { user }
    let(:extra_resource) { {} }

    let(:executor) do
      ai_request = ::Gitlab::Llm::Chain::Requests::Anthropic.new(user)
      context = ::Gitlab::Llm::Chain::GitlabContext.new(
        current_user: user,
        container: resource.try(:resource_parent)&.root_ancestor,
        resource: resource,
        ai_request: ai_request,
        extra_resource: extra_resource
      )

      all_tools = Gitlab::Llm::Completions::Chat::TOOLS.dup
      all_tools << ::Gitlab::Llm::Chain::Tools::EpicIdentifier
      all_tools << ::Gitlab::Llm::Chain::Tools::CiEditorAssistant

      described_class.new(
        user_input: input,
        tools: all_tools,
        context: context,
        response_handler: response_service_double
      )
    end

    before_all do
      group.add_owner(user)
    end

    before do
      stub_licensed_features(ai_features: true)
      stub_ee_application_setting(should_check_namespace_plan: true)
      group.namespace_settings.update!(
        third_party_ai_features_enabled: true,
        experiment_features_enabled: true
      )
      stub_licensed_features(ai_tanuki_bot: true)
      allow(response_service_double).to receive(:execute).at_least(:once)
    end

    shared_examples_for 'successful prompt processing' do
      it 'answers query using expected tools', :aggregate_failures do
        answer = executor.execute

        expect(executor.context).to match_llm_tools(tools)
        expect(answer.content).to match_llm_answer(answer_match)
      end
    end

    context 'with blob as resource' do
      let(:blob) { project.repository.blob_at("master", "files/ruby/popen.rb") }
      let(:extra_resource) { { blob: blob } }

      where(:input_template, :tools, :answer_match) do
        'Explain the code'          | [] | /ruby|popen/i
        'Explain this code'         | [] | /ruby|popen/i
        'What is this code doing?'  | [] | /ruby|popen/i
        'Can you explain the code ""def hello_world\\nputs(\""Hello, world!\\n\"");\nend""?' | [] | /hello/i
      end

      with_them do
        let(:input) { input_template }

        it_behaves_like 'successful prompt processing'
      end

      context 'with blob for code containing gitlab references' do
        let(:blob) do
          fixture = File.read('ee/spec/fixtures/llm/projects_controller.rb')

          fake_blob(path: 'app/controllers/explore/projects_controller.rb', data: fixture)
        end

        let(:input) { 'What is this code doing?' }
        let(:tools) { [] }
        let(:answer_match) { /ruby|rails/i }

        it_behaves_like 'successful prompt processing'
      end
    end

    context 'with predefined issue', time_travel_to: Time.utc(2023, 8, 11) do
      let_it_be(:due_date) { 3.days.from_now }
      let_it_be(:label) { create(:label, project: project, title: 'ai-enablement') }
      let_it_be(:milestone) { create(:milestone, project: project, title: 'milestone1', due_date: due_date) }
      let_it_be(:issue) do
        create(:issue, project: project, title: 'A testing issue for AI reliability',
          description: 'This issue is about evaluating reliability of various AI providers.',
          labels: [label], created_at: 2.days.ago, milestone: milestone)
      end

      context 'with predefined tools' do
        context 'with issue reference' do
          let(:input) { format(input_template, issue_identifier: "the issue #{issue.to_reference(full: true)}") }

          # rubocop: disable Layout/LineLength
          where(:input_template, :tools, :answer_match) do
            'Please summarize %<issue_identifier>s' | %w[IssueIdentifier ResourceReader] | /reliability/
            'Summarize %<issue_identifier>s with bullet points' | %w[IssueIdentifier ResourceReader] | /reliability/
            'Can you list all the labels on %<issue_identifier>s?' | %w[IssueIdentifier ResourceReader] | /ai-enablement/
            'How old is %<issue_identifier>s?' | %w[IssueIdentifier ResourceReader] | /2 days/
            'How many days ago %<issue_identifier>s was created?' | %w[IssueIdentifier ResourceReader] | //
            'For which milestone is %<issue_identifier>s? And how long until then' | %w[IssueIdentifier ResourceReader] | lazy { /(#{milestone&.title}|due date.*#{due_date.strftime("%Y-%m-%d")})/ }
            'What should be the final solution for %<issue_identifier>s?' | %w[IssueIdentifier ResourceReader] | /solution/
          end
          # rubocop: enable Layout/LineLength

          with_them do
            it_behaves_like 'successful prompt processing'
          end
        end

        context 'with `this issue`' do
          let(:resource) { issue }
          let(:input) { format(input_template, issue_identifier: "this issue") }

          # rubocop: disable Layout/LineLength
          where(:input_template, :tools, :answer_match) do
            'Please summarize %<issue_identifier>s' | %w[IssueIdentifier ResourceReader] | //
            'Can you list all the labels on %<issue_identifier>s?' | %w[IssueIdentifier ResourceReader] | /ai-enablement/
            'How old is %<issue_identifier>s?' | %w[IssueIdentifier ResourceReader] | /2 days/
            'How many days ago %<issue_identifier>s was created?' | %w[IssueIdentifier ResourceReader] | //
            'For which milestone is %<issue_identifier>s? And how long until then' | %w[IssueIdentifier ResourceReader] | lazy { /(#{milestone&.title}|due date.*#{due_date.strftime("%Y-%m-%d")})/ }
            'What should be the final solution for %<issue_identifier>s?' | %w[IssueIdentifier ResourceReader] | /solution/
          end
          # rubocop: enable Layout/LineLength

          with_them do
            it_behaves_like 'successful prompt processing'
          end
        end
      end

      context 'with chat history' do
        let_it_be(:issue2) do
          create(
            :issue,
            project: project,
            title: 'AI chat - send websocket subscription message also for user messages',
            description: 'To make sure that new messages are propagated to all chat windows ' \
                         '(e.g. if user has chat window open in multiple windows) we should send subscription ' \
                         'message for user messages too (currently we send messages only for AI responses)'
          )
        end

        let(:history) do
          [
            { role: 'user', content: "What is issue #{issue.to_reference(full: true)} about?" },
            {
              role: 'assistant', content: "The summary of issue is:\n\n## Provider Comparison\n" \
                                          "- Difficulty in evaluating which provider is better \n" \
                                          "- Both providers have pros and cons"
            }
          ]
        end

        before do
          uuid = SecureRandom.uuid

          history.each do |message|
            Gitlab::Llm::ChatStorage.new(user).add(
              { request_id: uuid, role: message[:role], content: message[:content] }
            )
          end
        end

        # rubocop: disable Layout/LineLength
        where(:input_template, :tools, :answer_match) do
          # evaluation of questions which involve processing of other resources is not reliable yet
          # because both IssueIdentifier and JsonReader tools assume we work with single resource:
          # IssueIdentifier overrides context.resource
          # JsonReader takes resource from context
          # So JsonReader twice with different action input
          'Can you provide more details about that issue?' | %w[IssueIdentifier ResourceReader] | /(reliability|providers)/
          'Can you reword your answer?' | [] | /provider/i
          'Can you simplify your answer?' | [] | /provider|simplify/i
        end
        # rubocop: enable Layout/LineLength

        with_them do
          let(:input) do
            format(input_template, issue_identifier: issue.to_reference(full: true),
              issue_identifier2: issue2.to_reference(full: true))
          end

          it_behaves_like 'successful prompt processing'
        end
      end
    end

    context 'when asking to explain code' do
      # rubocop: disable Layout/LineLength
      where(:input_template, :tools, :answer_match) do
        # NOTE: `tools: []` is the correct expected value.
        # There is no tool for explaining a code and the LLM answers the question directly.
        'Can you explain the code ""def hello_world\\nputs(\""Hello, world!\\n\"");\nend""?' | [] | /(ruby|method|hello_world)/i
        'Can you explain function ""def hello_world\\nputs(\""Hello, world!\\n\"");\nend""?' | [] | /(ruby|function|method|hello_world)/i
        'Write me tests for function ""def hello_world\\nputs(\""Hello, world!\\n\"");\nend""' | [] | /(ruby|test)/
        'What is the complexity of the function ""def hello_world\\nputs(\""Hello, world!\\n\"");\nend""?' | [] | /O\(1\)/
        'How would you refactor the ""def hello_world\\nputs(\""Hello, world!\\n\"");\nend"" code?' | [] | /(ruby|refactor)/i
        'Can you fix the bug in my ""def hello_world\\nput(\""Hello, world!\\n\"");\nend"" code?' | [] | /ruby/i
        'Create an example of how to use method ""def hello_world\\nput(\""Hello, world!\\n\"");\nend""' | [] | /(ruby|example|hello_world)/
        'Create a function to validate an e-mail address' | [] | /(validate|email address)/i
        'Create a function in Python to call the spotify API to get my playlists' | [] | /python/i
        'Create a tic tac toe game in Javascript' | [] | /javascript/i
        'What would the ""def hello_world\\nputs(\""Hello, world!\\n\"");\nend"" code look like in Python?' | [] | /python/i
      end
      # rubocop: enable Layout/LineLength

      with_them do
        let(:input) { input_template }

        it_behaves_like 'successful prompt processing'
      end
    end

    context 'when asking about how to use GitLab', :ai_embedding_fixtures do
      where(:input_template, :tools, :answer_match) do
        'How do I change my password in GitLab' | ['GitlabDocumentation'] | /password/
        'How do I fork a project?' | ['GitlabDocumentation'] | /fork/
        'How do I clone a repository?' | ['GitlabDocumentation'] | /clone/
        'How do I create a project template?' | ['GitlabDocumentation'] | /project/
      end

      with_them do
        let(:input) { input_template }

        it_behaves_like 'successful prompt processing'
      end
    end

    context 'with predefined epic' do
      let_it_be(:label) { create(:label, group: group, title: 'ai-framework') }
      let_it_be(:epic) do
        create(:epic, group: group, title: 'A testing epic for AI reliability',
          description: 'This epic is about evaluating reliability of different AI prompts in chat',
          labels: [label], created_at: 5.days.ago)
      end

      # rubocop: disable Layout/LineLength
      where(:input_template, :tools, :answer_match) do
        'Please summarize %<epic_identifier>s'                    | %w[EpicIdentifier ResourceReader] | //
        'Can you list all labels on %{epic_identifier} epic?'     | %w[EpicIdentifier ResourceReader] | /ai-framework/
        'How many days ago was %<epic_identifier>s epic created?' | %w[EpicIdentifier ResourceReader] | /5 days/

        let(:input) { format(input_template, epic_identifier: epic.to_reference(full: true)) }

        it_behaves_like 'successful prompt processing'
        context 'with epic as resource' do
          let(:resource) { epic }

          # rubocop: disable Layout/LineLength
          where(:input_template, :tools, :answer_match) do
            'Can you list all labels on this epic?'       | %w[EpicIdentifier ResourceReader] | /ai-framework/
            'How many days ago was current epic created?' | %w[EpicIdentifier ResourceReader] | /5 days/
          end
          # rubocop: enable Layout/LineLength

          with_them do
            let(:input) { input_template }

            it_behaves_like 'successful prompt processing'
          end
        end

        context 'with chat history' do
          let_it_be(:epic2) do
            create(
              :epic,
              group: group,
              title: 'AI chat - send websocket subscription message also for user messages',
              description: 'To make sure that new messages are propagated to all chat windows ' \
                           '(e.g. if user has chat window open in multiple windows) we should send subscription ' \
                           'message for user messages too (currently we send messages only for AI responses)'
            )
          end

          let(:history) do
            [
              { role: 'user', content: "What is epic #{epic.to_reference(full: true)} about?" },
              {
                role: 'assistant', content: "The summary of epic is:\n\n## Provider Comparison\n" \
                                            "- Difficulty in evaluating which provider is better \n" \
                                            "- Both providers have pros and cons"
              }
            ]
          end

          before do
            uuid = SecureRandom.uuid

            history.each do |message|
              Gitlab::Llm::ChatStorage.new(user).add(
                { request_id: uuid, role: message[:role], content: message[:content] }
              )
            end
          end

          # rubocop: disable Layout/LineLength
          where(:input_template, :tools, :answer_match) do
            # evaluation of questions which involve processing of other resources is not reliable yet
            # because both EpicIdentifier and JsonReader tools assume we work with single resource:
            # EpicIdentifier overrides context.resource
            # JsonReader takes resource from context
            # So JsonReader twice with different action input
            'Can you provide more details about that epic' | %w[EpicIdentifier ResourceReader] | /(reliability|providers)/
            # Translation would have to be explicitly allowed in prompt rules first
            # 'Can you translate your last answer to German?' | [] | /Anbieter/ # Anbieter == provider
            'Can you reword your answer?' | [] | /provider/i
          end
          # rubocop: enable Layout/LineLength

          with_them do
            let(:input) do
              format(input_template, epic_identifier: epic.to_reference(full: true),
                epic_identifier2: epic2.to_reference(full: true))
            end

            it_behaves_like 'successful prompt processing'
          end
        end
      end
    end

    context 'when asked about CI/CD' do
      where(:input_template, :tools, :answer_match) do
        'How do I configure CI/CD pipeline to deploy a ruby application to k8s?' |
          ['CiEditorAssistant'] | /gitlab-ci/
        'Please help me configure a CI/CD pipeline for node application that would run lint and unit tests.' |
          ['CiEditorAssistant'] | /gitlab-ci/
        'Please provide a .gitlab-ci.yaml config for running a review app for merge requests?' |
          ['CiEditorAssistant'] | /gitlab-ci/
      end

      with_them do
        let(:input) { format(input_template) }

        it_behaves_like 'successful prompt processing'
      end
    end

    context 'when asked general questions' do
      let(:input) { format('What is your name?') }

      it 'answers question about a name', :aggregate_failures do
        answer = executor.execute

        expect(answer.content).to match_llm_answer('GitLab Duo Chat')
      end
    end
  end
end
