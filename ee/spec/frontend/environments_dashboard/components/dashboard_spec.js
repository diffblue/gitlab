import { GlButton, GlEmptyState, GlModal, GlSprintf, GlLink, GlPagination } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import component from 'ee/environments_dashboard/components/dashboard/dashboard.vue';
import Environment from 'ee/environments_dashboard/components/dashboard/environment.vue';
import ProjectHeader from 'ee/environments_dashboard/components/dashboard/project_header.vue';
import { getStoreConfig } from 'ee/vue_shared/dashboards/store/index';
import state from 'ee/vue_shared/dashboards/store/state';
import { trimText } from 'helpers/text_helper';
import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';

import environment from './mock_environment.json';

Vue.use(Vuex);

describe('dashboard', () => {
  let actionSpies;
  let wrapper;
  let propsData;
  let store;

  beforeEach(() => {
    actionSpies = {
      addProjectsToDashboard: jest.fn(),
      clearSearchResults: jest.fn(),
      setSearchQuery: jest.fn(),
      fetchSearchResults: jest.fn(),
      removeProject: jest.fn(),
      toggleSelectedProject: jest.fn(),
      fetchNextPage: jest.fn(),
      fetchProjects: jest.fn(),
    };

    const { actions, ...storeConfig } = getStoreConfig();
    store = new Vuex.Store({
      ...storeConfig,
      actions: {
        ...actions,
        ...actionSpies,
      },
    });

    propsData = {
      addPath: 'mock-addPath',
      listPath: 'mock-listPath',
      emptyDashboardSvgPath: '/assets/illustrations/operations-dashboard_empty.svg',
      emptyDashboardHelpPath: '/help/user/operations_dashboard/index.html',
      environmentsDashboardHelpPath: '/help/user/operations_dashboard/index.html',
    };

    wrapper = shallowMount(component, {
      propsData,
      store,
      stubs: { GlSprintf },
    });
  });

  afterEach(() => {
    store.replaceState(state());
  });

  const findPagination = () => wrapper.findComponent(GlPagination);

  it('should match the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders the dashboard title', () => {
    expect(wrapper.find('.js-dashboard-title').text()).toBe('Environments Dashboard');
  });

  it('should render the empty state component', () => {
    expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
  });

  it('should not render pagination in empty state', () => {
    expect(findPagination().exists()).toBe(false);
  });

  describe('page limits information message', () => {
    let message;

    beforeEach(() => {
      message = wrapper.find('.js-page-limits-message');
    });

    it('renders the message', () => {
      expect(trimText(message.text())).toBe(
        'This dashboard displays 3 environments per project, and is linked to the Operations Dashboard. When you add or remove a project from one dashboard, GitLab adds or removes the project from the other. More information',
      );
    });

    it('includes the correct documentation link in the message', () => {
      const helpLink = message.findComponent(GlLink);

      expect(helpLink.text()).toBe('More information');
      expect(helpLink.attributes('href')).toBe(propsData.environmentsDashboardHelpPath);
    });
  });

  describe('add projects button', () => {
    let button;

    beforeEach(() => {
      button = wrapper.findComponent(GlButton);
    });

    it('is labelled correctly', () => {
      expect(button.text()).toBe('Add projects');
    });
  });

  describe('wrapped components', () => {
    beforeEach(() => {
      store.state.projects = [
        {
          id: 0,
          name: 'test',
          namespace: { name: 'test', id: 0 },
          environments: [{ ...environment, id: 0 }, environment],
        },
        { id: 1, name: 'test', namespace: { name: 'test', id: 0 }, environments: [environment] },
      ];
    });

    describe('project header', () => {
      it('should have one project header per project', () => {
        const headers = wrapper.findAllComponents(ProjectHeader);
        expect(headers).toHaveLength(2);
      });

      it('should remove a project if it emits `remove`', () => {
        const header = wrapper.findComponent(ProjectHeader);
        header.vm.$emit('remove');
        expect(actionSpies.removeProject).toHaveBeenCalled();
      });
    });

    describe('environment component', () => {
      it('should have one environment component per environment', () => {
        const environments = wrapper.findAllComponents(Environment);
        expect(environments).toHaveLength(3);
      });
    });

    describe('project selector modal', () => {
      beforeEach(async () => {
        wrapper.findComponent(GlButton).trigger('click');
        await nextTick();
      });

      it('should fire the add projects action on ok', () => {
        wrapper.findComponent(GlModal).vm.$emit('ok');
        expect(actionSpies.addProjectsToDashboard).toHaveBeenCalled();
      });

      it('should fire clear search when the modal is hidden', () => {
        wrapper.findComponent(GlModal).vm.$emit('hidden');
        expect(actionSpies.clearSearchResults).toHaveBeenCalled();
      });

      it('should set the search query when searching', () => {
        wrapper.findComponent(ProjectSelector).vm.$emit('searched', 'test');
        expect(actionSpies.setSearchQuery).toHaveBeenCalledWith(expect.any(Object), 'test');
      });

      it('should fetch query results when searching', () => {
        wrapper.findComponent(ProjectSelector).vm.$emit('searched', 'test');
        expect(actionSpies.fetchSearchResults).toHaveBeenCalled();
      });

      it('should toggle a project when clicked', () => {
        wrapper.findComponent(ProjectSelector).vm.$emit('projectClicked', { name: 'test', id: 1 });
        expect(actionSpies.toggleSelectedProject).toHaveBeenCalledWith(expect.any(Object), {
          name: 'test',
          id: 1,
        });
      });

      it('should fetch the next page when bottom is reached', () => {
        wrapper.findComponent(ProjectSelector).vm.$emit('bottomReached');
        expect(actionSpies.fetchNextPage).toHaveBeenCalled();
      });

      it('should get the page info from the state', async () => {
        store.state.pageInfo = { totalResults: 100 };

        await nextTick();
        expect(wrapper.findComponent(ProjectSelector).props('totalResults')).toBe(100);
      });
    });

    describe('pagination', () => {
      const testPagination = async ({ totalPages }) => {
        store.state.projectsPage.pageInfo.totalPages = totalPages;
        const shouldRenderPagination = totalPages > 1;

        await nextTick();
        expect(findPagination().exists()).toBe(shouldRenderPagination);
      };

      it('should not render the pagination component if there is only one page', () =>
        testPagination({ totalPages: 1 }));

      it('should render the pagination component if there are multiple pages', () =>
        testPagination({ totalPages: 2 }));
    });
  });
});
