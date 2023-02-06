# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project show page', :feature, feature_category: :projects do
  let_it_be(:user) { create(:user) }

  describe 'stat button existence' do
    describe 'populated project' do
      let(:project) { create(:project, :public, :repository) }

      describe 'as a maintainer' do
        before do
          project.add_maintainer(user)
          sign_in(user)

          visit project_path(project)
        end

        it '"Kubernetes cluster" button linked to clusters page' do
          create(:cluster, :provided_by_gcp, projects: [project])
          create(:cluster, :provided_by_gcp, :production_environment, projects: [project])

          visit project_path(project)

          page.within('.project-buttons') do
            expect(page).to have_link('Kubernetes', href: project_clusters_path(project))
          end
        end
      end
    end
  end

  describe 'pull mirroring information' do
    let_it_be(:project) do
      create(:project, :repository, mirror: true, mirror_user: user, import_url: 'http://user:pass@test.com')
    end

    context 'for maintainer' do
      before do
        project.add_maintainer(user)
        sign_in(user)

        visit project_path(project)
      end

      it 'displays mirrored from url' do
        expect(page).to have_content("Mirrored from http://*****:*****@test.com")
      end
    end

    context 'for guest' do
      before do
        project.add_guest(user)
        sign_in(user)

        visit project_path(project)
      end

      it 'does not display mirrored from url' do
        expect(page).not_to have_content("Mirrored from http://*****:*****@test.com")
      end
    end
  end

  context 'when over free user limit', :saas do
    subject(:visit_page) { visit project_path(project) }

    context 'with group namespace' do
      let(:role) { :owner }
      let_it_be(:group) { create(:group_with_plan, :private, plan: :free_plan) }

      before do
        group.add_member(user, role)
        sign_in(user)
      end

      context 'with repository' do
        let_it_be(:project) { create(:project, :repository, :private, group: group) }

        it_behaves_like 'over the free user limit alert'
      end

      context 'with empty repository' do
        let_it_be(:project) { create(:project, :empty_repo, :private, group: group) }

        it_behaves_like 'over the free user limit alert'
      end

      context 'without repository' do
        let_it_be(:project) { create(:project, :private, group: group) }

        it_behaves_like 'over the free user limit alert'
      end
    end
  end
end
