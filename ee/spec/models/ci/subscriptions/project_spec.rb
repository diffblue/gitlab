# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Subscriptions::Project do
  let_it_be_with_reload(:upstream_project) { create(:project, :public) }
  let_it_be_with_reload(:downstream_project) { create(:project) }

  describe 'Relations' do
    it { is_expected.to belong_to(:downstream_project).required }
    it { is_expected.to belong_to(:upstream_project).required }
    it { is_expected.to belong_to(:author) }
  end

  it_behaves_like 'includes Limitable concern' do
    let_it_be_with_reload(:user) { create(:user) }

    subject do
      build(
        :ci_subscriptions_project,
        upstream_project: upstream_project,
        downstream_project: downstream_project,
        author: user
      )
    end
  end

  describe 'Validations' do
    let!(:subscription) { create(:ci_subscriptions_project, upstream_project: upstream_project) }

    it { is_expected.to validate_uniqueness_of(:upstream_project_id).scoped_to(:downstream_project_id) }

    it 'validates that upstream project is public' do
      upstream_project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

      expect(subscription).not_to be_valid
    end
  end

  context 'loose foreign key on ci_subscriptions_projects.downstream_project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:project) }
      let!(:model) { create(:ci_subscriptions_project, downstream_project: parent) }
    end
  end

  context 'loose foreign key on ci_subscriptions_projects.upstream_project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:project, :public) }
      let!(:model) { create(:ci_subscriptions_project, upstream_project: parent) }
    end
  end

  context 'loose foreign key on ci_subscriptions_projects.author_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:user) }
      let!(:model) { create(:ci_subscriptions_project, author: parent) }
    end
  end

  describe '.with_downstream_and_author' do
    it 'includes the author and downstream project' do
      author = create(:user)
      subscription = create(
        :ci_subscriptions_project,
        upstream_project: upstream_project,
        downstream_project: downstream_project,
        author: author
      )

      refound_subscription = described_class.where(id: subscription.id).with_downstream_and_author.first

      expect do
        expect(refound_subscription.author).to eq(author)
        expect(refound_subscription.downstream_project).to eq(downstream_project)
      end.not_to exceed_query_limit(0)
    end
  end
end
