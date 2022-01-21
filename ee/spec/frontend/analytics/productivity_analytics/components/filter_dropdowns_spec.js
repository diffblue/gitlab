import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import FilterDropdowns from 'ee/analytics/productivity_analytics/components/filter_dropdowns.vue';
import { getStoreConfig } from 'ee/analytics/productivity_analytics/store';
import GroupsDropdownFilter from 'ee/analytics/shared/components/groups_dropdown_filter.vue';
import ProjectsDropdownFilter from '~/analytics/shared/components/projects_dropdown_filter.vue';
import resetStore from '../helpers';

Vue.use(Vuex);

describe('FilterDropdowns component', () => {
  let wrapper;
  let mockStore;

  const filtersActionSpies = {
    setGroupNamespace: jest.fn(),
    setProjectPath: jest.fn(),
  };

  const groupId = 1;
  const groupNamespace = 'gitlab-org';
  const projectPath = 'gitlab-org/gitlab-test';
  const projectId = 'gid://gitlab/Project/1';

  beforeEach(() => {
    const {
      modules: { filters, ...modules },
      ...storeConfig
    } = getStoreConfig();
    mockStore = new Vuex.Store({
      ...storeConfig,
      modules: {
        filters: {
          ...filters,
          actions: {
            ...filters.actions,
            ...filtersActionSpies,
          },
        },
        ...modules,
      },
    });

    wrapper = shallowMount(FilterDropdowns, {
      store: mockStore,
      propsData: {},
    });
  });

  afterEach(() => {
    wrapper.destroy();
    resetStore(mockStore);
  });

  describe('template', () => {
    it('renders the groups dropdown', () => {
      expect(wrapper.findComponent(GroupsDropdownFilter).exists()).toBe(true);
    });

    describe('without a group selected', () => {
      beforeEach(() => {
        wrapper.vm.groupId = null;
      });

      it('does not render the projects dropdown', () => {
        expect(wrapper.findComponent(ProjectsDropdownFilter).exists()).toBe(false);
      });
    });

    describe('with a group selected', () => {
      beforeEach(() => {
        wrapper.vm.groupId = groupId;
        mockStore.state.filters.groupNamespace = groupNamespace;
      });

      it('renders the projects dropdown', () => {
        expect(wrapper.findComponent(ProjectsDropdownFilter).exists()).toBe(true);
      });
    });
  });

  describe('methods', () => {
    describe('onGroupSelected', () => {
      beforeEach(() => {
        wrapper.vm.onGroupSelected({ id: groupId, full_path: groupNamespace });
      });

      it('updates the groupId and invokes setGroupNamespace action', () => {
        expect(wrapper.vm.groupId).toBe(1);
        const { calls } = filtersActionSpies.setGroupNamespace.mock;
        expect(calls[calls.length - 1][1]).toBe(groupNamespace);
      });

      it('emits the "groupSelected" event', () => {
        expect(wrapper.emitted().groupSelected[0][0]).toEqual({
          groupNamespace,
          groupId,
        });
      });
    });

    describe('onProjectsSelected', () => {
      beforeEach(() => {
        wrapper.vm.groupId = groupId;
      });

      describe('when the list of selected projects is not empty', () => {
        beforeEach(() => {
          mockStore.state.filters.groupNamespace = groupNamespace;
          wrapper.vm.onProjectsSelected([{ id: projectId, fullPath: `${projectPath}` }]);
        });

        it('invokes setProjectPath action', () => {
          const { calls } = filtersActionSpies.setProjectPath.mock;
          expect(calls[calls.length - 1][1]).toBe(projectPath);
        });

        it('emits the "projectSelected" event', () => {
          expect(wrapper.emitted().projectSelected[0][0]).toEqual({
            groupNamespace,
            groupId,
            projectNamespace: projectPath,
            projectId,
          });
        });
      });

      describe('when the list of selected projects is empty', () => {
        beforeEach(() => {
          mockStore.state.filters.groupNamespace = groupNamespace;
          wrapper.vm.onProjectsSelected([]);
        });

        it('invokes setProjectPath action with null', () => {
          const { calls } = filtersActionSpies.setProjectPath.mock;
          expect(calls[calls.length - 1][1]).toBe(null);
        });

        it('emits the "projectSelected" event', () => {
          expect(wrapper.emitted().projectSelected[0][0]).toEqual({
            groupNamespace,
            groupId,
            projectNamespace: null,
            projectId: null,
          });
        });
      });
    });
  });
});
