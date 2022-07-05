# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetsFinder do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:private_project_snippet) { create(:project_snippet, :private, project: project) }
  let_it_be(:internal_project_snippet) { create(:project_snippet, :internal, project: project) }
  let_it_be(:public_project_snippet) { create(:project_snippet, :public, project: project) }

  let(:finder_params) { {} }
  let(:finder_user) {}

  subject { described_class.new(finder_user, finder_params).execute }

  context 'filter by project' do
    let_it_be(:user) { create(:user, :auditor) }

    let(:finder_params) { { project: project } }
    let(:finder_user) { user }

    it 'returns all snippets for auditor users' do
      expect(subject).to match_array([private_project_snippet, internal_project_snippet, public_project_snippet])
    end
  end

  context 'filter by authorized snippet projects and authored personal' do
    let_it_be(:user) { create(:user) }
    let_it_be(:other_user) { create(:user) }
    let_it_be(:other_project) { create(:project) }
    let_it_be(:private_personal_snippet) { create(:personal_snippet, :private, author: user) }
    let_it_be(:internal_personal_snippet) { create(:personal_snippet, :internal, author: user) }
    let_it_be(:public_personal_snippet) { create(:personal_snippet, :public, author: user) }
    let_it_be(:other_private_personal_snippet) { create(:personal_snippet, :private, author: other_user) }
    let_it_be(:other_internal_personal_snippet) { create(:personal_snippet, :internal, author: other_user) }
    let_it_be(:other_public_personal_snippet) { create(:personal_snippet, :public, author: other_user) }
    let_it_be(:other_private_project_snippet) { create(:project_snippet, :private, project: other_project, author: other_user) }
    let_it_be(:other_internal_project_snippet) { create(:project_snippet, :internal, project: other_project, author: other_user) }
    let_it_be(:other_public_project_snippet) { create(:project_snippet, :public, project: other_project, author: other_user) }

    let(:finder_params) { { authorized_and_user_personal: true } }
    let(:finder_user) { user }

    context 'when no user' do
      let(:finder_user) {}

      it 'returns only public personal snippets' do
        expect(subject).to contain_exactly(public_personal_snippet, other_public_personal_snippet)
      end
    end

    context 'when user is not a member of any project' do
      it 'returns only user personal snippets' do
        expect(subject).to match_array([public_personal_snippet, internal_personal_snippet, private_personal_snippet])
      end
    end

    context 'when the user is a member of a project' do
      [:guest, :reporter, :developer, :maintainer].each do |role|
        it 'returns all the authorized project snippets and authored personal ones' do
          project.add_role(user, role)

          expect(subject)
            .to contain_exactly(
              public_personal_snippet,
              internal_personal_snippet,
              private_personal_snippet,
              public_project_snippet,
              internal_project_snippet,
              private_project_snippet
            )
        end
      end

      [:guest, :reporter, :developer, :maintainer].each do |role|
        it 'returns all the authorized project snippets and authored personal ones' do
          project.add_role(user, role)
          other_project.add_role(user, role)

          expect(subject)
            .to contain_exactly(
              public_personal_snippet,
              internal_personal_snippet,
              private_personal_snippet,
              public_project_snippet,
              internal_project_snippet,
              private_project_snippet,
              other_private_project_snippet,
              other_internal_project_snippet,
              other_public_project_snippet
            )
        end
      end

      context 'when user cannot read_cross_project' do
        before do
          project.add_maintainer(user)
          allow(Ability).to receive(:allowed?)
                          .with(user, :read_cross_project)
                          .and_return(false)
        end

        it 'returns only user personal snippets' do
          expect(subject).to contain_exactly(public_personal_snippet, internal_personal_snippet, private_personal_snippet)
        end
      end
    end

    context 'when the user is a member of a group' do
      [:guest, :reporter, :developer, :maintainer].each do |role|
        it 'returns all the authorized project snippets and authored personal ones' do
          group.add_member(user, role)

          expect(subject)
            .to contain_exactly(
              public_personal_snippet,
              internal_personal_snippet,
              private_personal_snippet,
              public_project_snippet,
              internal_project_snippet,
              private_project_snippet
            )
        end
      end
    end

    context 'when param author is passed' do
      let(:finder_params) { { author: other_user, authorized_and_user_personal: true } }

      context 'when user is not a member of any project' do
        it 'returns only the author visible personal snippets to the user' do
          expect(subject).to contain_exactly(other_public_personal_snippet, other_internal_personal_snippet)
        end
      end

      context 'when user is a member of a project' do
        [:guest, :reporter, :developer, :maintainer].each do |role|
          it 'returns all the authorized project and personal snippets authored by the author' do
            project.add_role(user, role)
            other_project.add_role(user, role)

            expect(subject)
              .to contain_exactly(
                other_public_personal_snippet,
                other_internal_personal_snippet,
                other_internal_project_snippet,
                other_public_project_snippet,
                other_private_project_snippet
              )
          end
        end
      end
    end

    context 'when only_personal is passed' do
      let(:finder_params) { { authorized_and_user_personal: true, only_personal: true } }

      it 'returns only personal snippets' do
        group.add_maintainer(user)

        expect(subject)
          .to contain_exactly(
            public_personal_snippet,
            internal_personal_snippet,
            private_personal_snippet
          )
      end
    end

    context 'when only_project is passed' do
      let(:finder_params) { { authorized_and_user_personal: true, only_project: true } }

      it 'returns only project snippets' do
        group.add_maintainer(user)

        expect(subject)
          .to contain_exactly(
            public_project_snippet,
            internal_project_snippet,
            private_project_snippet
          )
      end

      context 'when no personal snippets are visible' do
        let(:user) { nil }

        it 'does not return any record' do
          expect(subject).to be_empty
        end
      end
    end
  end
end
