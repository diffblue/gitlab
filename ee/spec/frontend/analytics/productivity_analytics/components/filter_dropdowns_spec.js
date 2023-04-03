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

  const createWrapper = (propsData = {}) => {
    const {
      modules: { filters, ...modules },
      ...storeConfig
    } = getStoreConfig();
    mockStore = new Vuex.Store({
      ...storeConfig,
      modules: {
        filters: {
          ...filters,
          state: {
            ...filters.state,
            groupNamespace,
          },
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
      propsData,
    });
  };

  const findGroupsDropdownFilter = () => wrapper.findComponent(GroupsDropdownFilter);
  const findProjectsDropdownFilter = () => wrapper.findComponent(ProjectsDropdownFilter);

  afterEach(() => {
    // eslint-disable-next-line @gitlab/vtu-no-explicit-wrapper-destroy
    wrapper.destroy();
    resetStore(mockStore);
  });

  describe('template', () => {
    it('renders the groups dropdown', () => {
      createWrapper();
      expect(findGroupsDropdownFilter().exists()).toBe(true);
    });

    describe('without a group selected', () => {
      beforeEach(() => {
        createWrapper({ group: { id: null } });
      });

      it('does not render the projects dropdown', () => {
        expect(findProjectsDropdownFilter().exists()).toBe(false);
      });
    });

    describe('with a group selected', () => {
      beforeEach(() => {
        createWrapper({ group: { id: groupId } });
      });

      it('renders the projects dropdown', () => {
        expect(findProjectsDropdownFilter().exists()).toBe(true);
      });
    });
  });

  describe('events', () => {
    describe('when group is selected', () => {
      beforeEach(() => {
        createWrapper({ group: { id: null } });
        findGroupsDropdownFilter().vm.$emit('selected', { id: groupId, full_path: groupNamespace });
      });

      it('invokes setGroupNamespace action and renders the projects dropdown', () => {
        const { calls } = filtersActionSpies.setGroupNamespace.mock;
        expect(calls[calls.length - 1][1]).toBe(groupNamespace);
        expect(findProjectsDropdownFilter().exists()).toBe(true);
      });

      it('emits the "groupSelected" event', () => {
        expect(wrapper.emitted().groupSelected[0][0]).toEqual({
          groupNamespace,
          groupId,
        });
      });
    });

    describe('with group selected', () => {
      beforeEach(() => {
        createWrapper({ group: { id: groupId } });
      });

      describe('when project is selected', () => {
        beforeEach(() => {
          const selectedProject = [{ id: projectId, fullPath: `${projectPath}` }];
          findProjectsDropdownFilter().vm.$emit('selected', selectedProject);
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

      describe('when project is deselected', () => {
        beforeEach(() => {
          findProjectsDropdownFilter().vm.$emit('selected', []);
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
