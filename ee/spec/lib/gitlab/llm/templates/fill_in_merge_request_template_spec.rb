# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Templates::FillInMergeRequestTemplate, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.owner }
  let(:source_project) { project }

  let(:params) do
    {
      source_project_id: source_project.id,
      source_branch: 'feature',
      target_branch: 'master',
      title: 'A merge request',
      content: 'This is content'
    }
  end

  subject { described_class.new(user, project, params) }

  describe '#to_prompt' do
    it 'includes title param' do
      expect(subject.to_prompt).to include(params[:title])
    end

    it 'includes raw diff' do
      expect(subject.to_prompt)
        .to include("+class Feature\n+  def foo\n+    puts 'bar'\n+  end\n+end")
    end

    it 'includes the content' do
      expect(subject.to_prompt).to include('This is content')
    end

    context 'when user cannot create merge request from source_project_id' do
      let(:source_project) { create(:project) }

      it 'includes diff comparison from project' do
        expect(subject.to_prompt)
          .to include("+class Feature\n+  def foo\n+    puts 'bar'\n+  end\n+end")
      end
    end

    context 'when no source_project_id is specified' do
      let(:params) do
        {
          source_branch: 'feature',
          target_branch: 'master',
          title: 'A merge request',
          content: 'This is content'
        }
      end

      it 'includes diff comparison from project' do
        expect(subject.to_prompt)
          .to include("+class Feature\n+  def foo\n+    puts 'bar'\n+  end\n+end")
      end
    end
  end
end
