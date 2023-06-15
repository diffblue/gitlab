# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::API::Helpers do
  include Rack::Test::Methods

  let(:helper) do
    Class.new(Grape::API::Instance) do
      helpers EE::API::Helpers
      helpers API::APIGuard::HelperMethods
      helpers API::Helpers
      format :json

      get 'user' do
        current_user ? { id: current_user.id } : { found: false }
      end

      get 'protected' do
        authenticate_by_gitlab_geo_node_token!
      end
    end
  end

  def app
    helper
  end

  describe '#authenticate_by_gitlab_geo_node_token!' do
    let(:invalid_geo_auth_header) { "#{::Gitlab::Geo::BaseRequest::GITLAB_GEO_AUTH_TOKEN_TYPE}...Test" }

    it 'rescues from ::Gitlab::Geo::InvalidDecryptionKeyError' do
      expect_any_instance_of(::Gitlab::Geo::JwtRequestDecoder).to receive(:decode) { raise ::Gitlab::Geo::InvalidDecryptionKeyError }

      header 'Authorization', invalid_geo_auth_header
      get 'protected', params: { current_user: 'test' }

      expect(Gitlab::Json.parse(last_response.body)).to eq({ 'message' => 'Gitlab::Geo::InvalidDecryptionKeyError' })
    end

    it 'rescues from ::Gitlab::Geo::InvalidSignatureTimeError' do
      allow_any_instance_of(::Gitlab::Geo::JwtRequestDecoder).to receive(:decode) { raise ::Gitlab::Geo::InvalidSignatureTimeError }

      header 'Authorization', invalid_geo_auth_header
      get 'protected', params: { current_user: 'test' }

      expect(Gitlab::Json.parse(last_response.body)).to eq({ 'message' => 'Gitlab::Geo::InvalidSignatureTimeError' })
    end

    it 'returns unauthorized response when scope is not valid' do
      allow_any_instance_of(::Gitlab::Geo::JwtRequestDecoder).to receive(:decode).and_return(scope: 'invalid_scope')

      header 'Authorization', 'test'
      get 'protected', params: { current_user: 'test' }

      expect(Gitlab::Json.parse(last_response.body)).to eq({ 'message' => '401 Unauthorized' })
    end
  end

  describe '#authorize_change_param' do
    subject { Class.new.include(described_class).new }

    let(:project) { create(:project) }

    before do
      allow(subject).to receive(:params).and_return({ change_commit_committer_check: true })
    end

    it 'does not throw exception if param is authorized' do
      allow(subject).to receive(:authorize!).and_return(nil)

      expect { subject.authorize_change_param(project, :change_commit_committer_check) }.not_to raise_error
    end

    context 'unauthorized param' do
      let(:exception) { Exception.new('Forbidden') }

      before do
        allow(subject).to receive(:authorize!).and_raise(exception)
      end

      it 'throws exception if unauthorized param is present' do
        expect { subject.authorize_change_param(project, :change_commit_committer_check) }
          .to raise_error(exception)
      end

      it 'does not throw exception is unauthorized param is not present' do
        expect { subject.authorize_change_param(project, :reject_unsigned_commit) }.not_to raise_error
      end
    end
  end

  describe '#find_project!' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:job) { create(:ci_build, :running) }

    let(:helper) do
      Class.new do
        include API::Helpers
        include API::APIGuard::HelperMethods
        include EE::API::Helpers
      end
    end

    subject { helper.new }

    context 'when current_user is from a job' do
      before do
        subject.instance_variable_set(:@current_authenticated_job, job)
        subject.instance_variable_set(:@initial_current_user, job.user)
        subject.instance_variable_set(:@current_user, job.user)
      end

      context 'public project' do
        it 'returns requested project' do
          expect(subject.find_project!(project.id)).to eq(project)
        end
      end

      context 'private project without access' do
        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value('private'))
        end

        it 'returns not found' do
          expect(subject).to receive(:not_found!)

          subject.find_project!(project.id)
        end
      end
    end
  end

  describe '#find_subscription_add_on!' do
    subject(:find_or_create_subscription_add_on!) { helper.find_or_create_subscription_add_on!(name) }

    let(:helper) do
      klass = Class.new do
        include API::Helpers
        include EE::API::Helpers
      end

      klass.new
    end

    let(:name) { GitlabSubscriptions::AddOn.names.each_key.first }

    context 'when add-on name is not a defined one' do
      let(:name) { 'non-existing-add-on' }

      it 'returns not found' do
        allow(helper).to receive(:not_found!).and_raise(ActiveRecord::RecordNotFound)

        expect { find_or_create_subscription_add_on! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when add-on does not exist' do
      it 'creates the add-on' do
        expect { find_or_create_subscription_add_on! }.to change { GitlabSubscriptions::AddOn.count }
        expect(GitlabSubscriptions::AddOn.last).to have_attributes(
          name: name,
          description: GitlabSubscriptions::AddOn.descriptions[name.to_sym]
        )
      end
    end

    context 'when add-on exists' do
      it 'returns found add-on' do
        subscription_add_on = create(:gitlab_subscription_add_on, name: name)

        expect(find_or_create_subscription_add_on!).to eq(subscription_add_on)
      end
    end
  end

  describe '#find_subscription_add_on_purchase!' do
    subject(:find_subscription_add_on_purchase!) do
      helper = Class.new.include(described_class).new
      helper.find_subscription_add_on_purchase!(namespace, subscription_add_on)
    end

    let(:namespace) { create(:group) }
    let(:subscription_add_on) { create(:gitlab_subscription_add_on) }

    shared_examples 'not found' do
      it 'returns not found' do
        expect { find_subscription_add_on_purchase! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when namespace does not exist' do
      let(:add_on) { nil }

      include_examples 'not found'
    end

    context 'when add-on does not exist' do
      let(:namespace) { nil }

      include_examples 'not found'
    end

    context 'when namespace and add-on exist' do
      context 'when add-on purchase exists' do
        let!(:subscription_add_on_purchase) do
          create(:gitlab_subscription_add_on_purchase, namespace: namespace, add_on: subscription_add_on)
        end

        it 'returns found add-on purchase' do
          expect(find_subscription_add_on_purchase!).to eq(subscription_add_on_purchase)
        end
      end

      context 'when add-on purchase does not exist' do
        include_examples 'not found'
      end
    end
  end
end
