# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::CiEditorAssistant::Prompts::VertexAi, feature_category: :pipeline_composition do
  describe '.prompt' do
    it 'returns prompt' do
      prompt = described_class.prompt({ input: 'foo' })[:prompt]

      expect(prompt).to include('foo')
      expect(prompt).to include(
        <<~PROMPT
          System: You are an ai assistant talking to a devops or software engineer.
          You should coach users to author a ".gitlab-ci.yml" file which can be used to create a GitLab pipeline.
          Please provide concrete and detailed yaml that implements what the user asks for as closely as possible, assuming a single yaml file will be used.

          Think step by step to provide the most accurate solution to the user problem. Make sure that all the stages you've defined in the yaml file are actually used in it.
          If you realise you require more input from the user, please describe what information is missing and ask them to provide it. Specifically check, if you have information about the application you're providing a configuration for, for example, the programming language used, or deployment targets.
          If any configuration is missing, such as configuration variables, connection strings, secrets and so on, assume it will be taken from GitLab Ci/CD variables. Please include the variables configuration block that would use these Ci/CD variables.

          Please include the commented sections explaining every configuration block, unless the user explicitly asks you to skip or not include comments.
        PROMPT
      )
    end
  end
end
