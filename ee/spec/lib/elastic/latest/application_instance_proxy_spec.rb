# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::ApplicationInstanceProxy do
  let_it_be(:project) { create(:project, :in_subgroup) }
  let(:group) { project.group }
  let(:target) { project.repository }
  let(:included_class) { Elasticsearch::Model::Proxy::InstanceMethodsProxy }

  subject { included_class.new(target) }

  describe '#es_parent' do
    let(:target) { create(:merge_request) }

    it 'includes project id' do
      expect(subject.es_parent).to eq("project_#{target.project.id}")
    end

    context 'when target type is in routing excluded list' do
      let(:target) { project }

      it 'is nil' do
        expect(subject.es_parent).to be_nil
      end
    end
  end

  describe '#namespace_ancestry' do
    it 'returns the full ancestry' do
      expect(subject.namespace_ancestry).to eq("#{group.parent.id}-#{group.id}-")
    end
  end
end
