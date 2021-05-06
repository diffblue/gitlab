# frozen_string_literal: true

# TODO: replace 'tag_list' by 'topic_list' as soon as the following MR is merged:
# https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60834

require 'spec_helper'

RSpec.describe Projects::TopicsFinder do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:other_user) { create(:user) }

    let_it_be(:group) { create(:group, :public) }
    let_it_be(:other_group) { create(:group, :public) }

    let_it_be(:user_private_project) { create(:project, :private, namespace: user.namespace) }
    let_it_be(:user_public_project) { create(:project, :public, namespace: user.namespace) }
    let_it_be(:other_user_private_project) { create(:project, :private, namespace: other_user.namespace) }
    let_it_be(:other_user_public_project) { create(:project, :public, namespace: other_user.namespace) }
    let_it_be(:group_private_project) { create(:project, :private, group: group) }
    let_it_be(:group_public_project) { create(:project, :public, group: group) }
    let_it_be(:other_group_private_project) { create(:project, :private, group: other_group) }
    let_it_be(:other_group_public_project) { create(:project, :public, group: other_group) }

    before do
      group.add_developer(user)
      other_group.add_developer(other_user)
    end

    context 'count' do
      before do
        user_public_project.update!(tag_list: 'aaa, bbb, ccc, ddd')
        other_user_public_project.update!(tag_list: 'bbb, ccc, ddd')
        group_public_project.update!(tag_list: 'ccc, ddd')
        other_group_public_project.update!(tag_list: 'ddd')
      end

      it 'returns topics with correct count' do
        topics = described_class.new.execute

        expect(topics.to_h { |topic| [topic.name, topic.count] }).to match({ "aaa" => 1, "bbb" => 2, "ccc" => 3, "ddd" => 4 })
      end
    end

    context 'filter projects' do
      before do
        user_private_project.update!(tag_list: 'topic1')
        user_public_project.update!(tag_list: 'topic2')
        other_user_private_project.update!(tag_list: 'topic3')
        other_user_public_project.update!(tag_list: 'topic4')
        group_private_project.update!(tag_list: 'topic5')
        group_public_project.update!(tag_list: 'topic6')
        other_group_private_project.update!(tag_list: 'topic7')
        other_group_public_project.update!(tag_list: 'topic8')
      end

      context 'with current_user' do
        using RSpec::Parameterized::TableSyntax

        where(:params, :expected_topics) do
          {}                       | %w[topic1 topic2 topic4 topic5 topic6 topic8]
          { all_available: true }  | %w[topic1 topic2 topic4 topic5 topic6 topic8]
          { all_available: false } | %w[topic1 topic2 topic5 topic6]
        end

        with_them do
          it 'returns correct topics of authorized projects and/or public projects' do
            topics = described_class.new(current_user: user, params: params).execute

            expect(topics.map(&:name)).to contain_exactly(*expected_topics)
          end
        end
      end

      context 'without current_user' do
        using RSpec::Parameterized::TableSyntax

        where(:params, :expected_topics) do
          {}                       | %w[topic2 topic4 topic6 topic8]
          { all_available: true }  | %w[topic2 topic4 topic6 topic8]
          { all_available: false } | %w[topic2 topic4 topic6 topic8]
        end

        with_them do
          it 'returns correct topics of public projects only' do
            topics = described_class.new(current_user: nil, params: params).execute

            expect(topics.map(&:name)).to contain_exactly(*expected_topics)
          end
        end
      end
    end

    context 'filter by name' do
      before do
        user_public_project.update!(tag_list: 'aaabbb, bbbccc, dDd, dddddd')
      end

      using RSpec::Parameterized::TableSyntax

      where(:search, :expected_topics) do
        ''       | %w[aaabbb bbbccc dDd dddddd]
        'aaabbb' | %w[aaabbb]
        'bbb'    | %w[aaabbb bbbccc]
        'ccc'    | %w[bbbccc]
        'DDD'    | %w[dDd dddddd]
        'zzz'    | %w[]
      end

      with_them do
        it 'returns correct topics filtered by name' do
          topics = described_class.new(params: { name: search }).execute

          expect(topics.map(&:name)).to contain_exactly(*expected_topics)
        end
      end
    end

    context 'sort by attribute' do
      before do
        user_public_project.update!(tag_list: 'aaa, bbb, ccc, ddd')
        other_user_public_project.update!(tag_list: 'bbb, ccc, ddd')
        group_public_project.update!(tag_list: 'bbb, ccc')
        other_group_public_project.update!(tag_list: 'ccc')
      end

      using RSpec::Parameterized::TableSyntax
      where(:sort, :expected_topics) do
        ''                | %w[ccc bbb ddd aaa]
        'name_asc'        | %w[aaa bbb ccc ddd]
        'name_desc'       | %w[ddd ccc bbb aaa]
        'popularity_desc' | %w[ccc bbb ddd aaa]
        'invalid_sort'    | %w[ccc bbb ddd aaa]
      end

      with_them do
        it 'returns topics in correct order' do
          topics = described_class.new(params: { sort: sort }).execute

          expect(topics.map(&:name)).to match(expected_topics)
        end
      end
    end
  end
end
