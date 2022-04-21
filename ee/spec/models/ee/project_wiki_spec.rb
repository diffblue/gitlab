# frozen_string_literal: true

require 'active_support/testing/time_helpers'
require 'spec_helper'

RSpec.describe ProjectWiki do
  it_behaves_like 'EE wiki model' do
    let(:wiki_container) { create(:project, :wiki_repo, namespace: user.namespace) }
    let(:wiki_repository_state) { create(:repository_state, project: wiki_container) }

    it 'uses Elasticsearch' do
      expect(subject).to be_a(Elastic::WikiRepositoriesSearch)
    end

    describe '#after_wiki_activity' do
      context 'with the touch_project_repository_state_updated_at FF enabled' do
        it 'updates project_repository_state activity', :freeze_time do
          wiki_repository_state.update!(
            last_wiki_updated_at: nil
          )

          subject.send(:after_wiki_activity)
          wiki_repository_state.reload

          expect(wiki_repository_state.last_wiki_updated_at).to be_like_time(Time.current)
        end
      end

      context 'with the touch_project_repository_state_updated_at FF disabled' do
        before do
          stub_feature_flags(touch_project_repository_state_updated_at: false)
        end

        it 'does not update project_repository_state activity', :freeze_time do
          wiki_repository_state.update!(
            last_wiki_updated_at: nil
          )

          subject.send(:after_wiki_activity)
          wiki_repository_state.reload

          expect(wiki_repository_state.last_wiki_updated_at).to be_nil
        end
      end
    end
  end
end
