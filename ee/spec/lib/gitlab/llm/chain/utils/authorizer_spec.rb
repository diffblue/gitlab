# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Utils::Authorizer, feature_category: :shared do
  let(:resource) { instance_double(Issue) }
  let(:container) { instance_double(Project) }
  let(:user) { instance_double(User) }

  shared_examples 'user authorization' do
    let(:namespace1) { instance_double(Namespaces::UserNamespace) }
    let(:namespace2) { instance_double(Group) }

    it 'returns true if user has paid namespaces with third party AI features enabled' do
      expect(user).to receive(:paid_namespaces).with(plans: ::EE::User::AI_SUPPORTED_PLANS)
        .and_return([namespace1, namespace2])
      expect(namespace1).to receive(:third_party_ai_features_enabled).and_return(false)
      expect(namespace2).to receive(:third_party_ai_features_enabled).and_return(true)
      expect(namespace2).to receive(:experiment_features_enabled).and_return(true)

      expect(subject).to be(true)
    end

    it 'returns false if user has no paid namespaces' do
      expect(user).to receive(:paid_namespaces).with(plans: ::EE::User::AI_SUPPORTED_PLANS).and_return([])

      expect(subject).to be(false)
    end

    it 'returns false if user has paid namespaces but no third party AI features enabled' do
      expect(user).to receive(:paid_namespaces).with(plans: ::EE::User::AI_SUPPORTED_PLANS)
        .and_return([namespace1, namespace2])
      expect(namespace1).to receive(:third_party_ai_features_enabled).and_return(false)
      expect(namespace2).to receive(:third_party_ai_features_enabled).and_return(false)

      expect(subject).to be(false)
    end
  end

  describe '.context_authorized?' do
    let(:context) { instance_double(Gitlab::Llm::Chain::GitlabContext) }

    subject { described_class.context_authorized?(context: context) }

    context 'when both resource and container are present' do
      before do
        allow(context).to receive(:resource).and_return(resource)
        allow(context).to receive(:container).and_return(container)
        allow(context).to receive(:current_user).and_return(user)
      end

      it 'returns true if both resource and container are authorized' do
        allow(described_class).to receive(:resource_authorized?).and_return(true)
        allow(described_class).to receive(:container_authorized?).and_return(true)

        expect(subject).to be(true)
      end

      it 'returns false if resource is not authorized' do
        allow(described_class).to receive(:resource_authorized?).and_return(false)
        allow(described_class).to receive(:container_authorized?).and_return(true)

        expect(subject).to be(false)
      end

      it 'returns false if container is not authorized' do
        allow(described_class).to receive(:resource_authorized?).and_return(true)
        allow(described_class).to receive(:container_authorized?).and_return(false)

        expect(subject).to be(false)
      end
    end

    context 'when only resource is present' do
      before do
        allow(context).to receive(:resource).and_return(resource)
        allow(context).to receive(:container).and_return(nil)
        allow(context).to receive(:current_user).and_return(user)
      end

      it 'returns true if resource is authorized' do
        allow(described_class).to receive(:resource_authorized?).and_return(true)

        expect(subject).to be(true)
      end

      it 'returns false if resource is not authorized' do
        allow(described_class).to receive(:resource_authorized?).and_return(false)

        expect(subject).to be(false)
      end
    end

    context 'when only container is present' do
      before do
        allow(context).to receive(:resource).and_return(nil)
        allow(context).to receive(:container).and_return(container)
        allow(context).to receive(:current_user).and_return(nil)
      end

      it 'returns true if container is authorized' do
        allow(described_class).to receive(:container_authorized?).and_return(true)

        expect(subject).to be(true)
      end

      it 'returns false if container is not authorized' do
        allow(described_class).to receive(:container_authorized?).and_return(false)

        expect(subject).to be(false)
      end
    end

    context 'when neither resource nor container is present' do
      before do
        allow(context).to receive(:resource).and_return(nil)
        allow(context).to receive(:container).and_return(nil)
        allow(context).to receive(:current_user).and_return(user)
      end

      it 'returns true if user is authorized' do
        allow(described_class).to receive(:user_authorized?).and_return(true)

        expect(subject).to be(true)
      end

      it 'returns false if user is not authorized' do
        allow(described_class).to receive(:user_authorized?).and_return(false)

        expect(subject).to be(false)
      end
    end
  end

  describe '.container_authorized?' do
    it "calls Gitlab::Llm::StageCheck.available? with the appropriate arguments" do
      expect(Gitlab::Llm::StageCheck).to receive(:available?).with(container, :chat)

      described_class.container_authorized?(container: container)
    end
  end

  describe '.resource_authorized?' do
    let(:root_ancestor) { instance_double(Group) }

    subject { described_class.resource_authorized?(resource: resource, user: user) }

    context 'when resource is nil' do
      let(:resource) { nil }

      it 'returns false' do
        expect(subject).to be_nil
      end
    end

    it 'returns false if resource parent is not authorized' do
      expect(resource).to receive_message_chain(:resource_parent, :root_ancestor).and_return(root_ancestor)
      expect(Gitlab::Llm::StageCheck).to receive(:available?).with(root_ancestor, :chat).and_return(false)

      expect(subject).to be(false)
    end

    it 'calls user.can? with the appropriate arguments' do
      expect(resource).to receive_message_chain(:resource_parent, :root_ancestor).and_return(root_ancestor)
      expect(Gitlab::Llm::StageCheck).to receive(:available?).with(root_ancestor, :chat).and_return(true)
      expect(resource).to receive(:to_ability_name).and_return('ability_name')
      expect(user).to receive(:can?).with('read_ability_name', resource)

      subject
    end

    context 'when resource is current user' do
      let(:resource) { user }

      it_behaves_like 'user authorization'
    end
  end

  describe '.user_authorized?' do
    subject { described_class.user_authorized?(user: user) }

    it_behaves_like 'user authorization'
  end
end
