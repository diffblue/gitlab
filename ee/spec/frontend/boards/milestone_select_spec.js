import { GlButton, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';

import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import MilestoneSelect from 'ee/boards/components/milestone_select.vue';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';

import { boardObj } from 'jest/boards/mock_data';
import {
  mockProjectMilestonesResponse,
  mockGroupMilestonesResponse,
  mockMilestone1,
} from 'jest/sidebar/mock_data';

import defaultStore from '~/boards/stores';
import groupMilestonesQuery from '~/sidebar/queries/group_milestones.query.graphql';
import projectMilestonesQuery from '~/sidebar/queries/project_milestones.query.graphql';
import DropdownWidget from '~/vue_shared/components/dropdown/dropdown_widget/dropdown_widget.vue';

Vue.use(VueApollo);
Vue.use(Vuex);

describe('Milestone select component', () => {
  let wrapper;
  let fakeApollo;
  let store;

  const selectedText = () => wrapper.find('[data-testid="selected-milestone"]').text();
  const findEditButton = () => wrapper.findComponent(GlButton);
  const findDropdown = () => wrapper.findComponent(DropdownWidget);

  const milestonesQueryHandlerSuccess = jest.fn().mockResolvedValue(mockProjectMilestonesResponse);
  const groupUsersQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupMilestonesResponse);

  const createStore = () => {
    store = new Vuex.Store({
      actions: {
        ...defaultStore.actions,
      },
    });
  };

  const createComponent = ({
    props = {},
    milestonesQueryHandler = milestonesQueryHandlerSuccess,
    isGroupBoard = false,
    isProjectBoard = false,
  } = {}) => {
    fakeApollo = createMockApollo([
      [projectMilestonesQuery, milestonesQueryHandler],
      [groupMilestonesQuery, groupUsersQueryHandlerSuccess],
    ]);
    wrapper = shallowMount(MilestoneSelect, {
      store,
      apolloProvider: fakeApollo,
      propsData: {
        board: boardObj,
        canEdit: true,
        ...props,
      },
      provide: {
        fullPath: 'gitlab-org',
        isGroupBoard,
        isProjectBoard,
      },
      stubs: {
        GlDropdown,
        GlDropdownItem,
        DropdownWidget: stubComponent(DropdownWidget, {
          methods: { showDropdown: jest.fn() },
        }),
      },
    });
  };

  beforeEach(() => {
    createStore();
    createComponent({ isProjectBoard: true });
  });

  afterEach(() => {
    fakeApollo = null;
    store = null;
  });

  describe('when not editing', () => {
    it("defaults to Don't filter milestone", () => {
      expect(selectedText()).toContain("Don't filter milestone");
    });

    it('skips the queries and does not render dropdown', () => {
      expect(milestonesQueryHandlerSuccess).not.toHaveBeenCalled();
      expect(findDropdown().isVisible()).toBe(false);
    });

    it('renders selected milestone', async () => {
      findEditButton().vm.$emit('click');
      await waitForPromises();
      findDropdown().vm.$emit('set-option', mockMilestone1);

      await waitForPromises();
      expect(selectedText()).toContain(mockMilestone1.title);
    });
  });

  describe('when editing', () => {
    it('trigger query and renders dropdown with passed milestones', async () => {
      findEditButton().vm.$emit('click');
      await waitForPromises();
      await nextTick();
      expect(milestonesQueryHandlerSuccess).toHaveBeenCalled();

      expect(findDropdown().isVisible()).toBe(true);
      expect(findDropdown().props('options')).toHaveLength(2);
    });
  });

  describe('canEdit', () => {
    it('hides Edit button', async () => {
      wrapper.setProps({ canEdit: false });
      await nextTick();

      expect(findEditButton().exists()).toBe(false);
    });

    it('shows Edit button if true', () => {
      expect(findEditButton().exists()).toBe(true);
    });
  });

  it.each`
    boardType    | mockedResponse                   | queryHandler                     | notCalledHandler
    ${'group'}   | ${mockGroupMilestonesResponse}   | ${groupUsersQueryHandlerSuccess} | ${milestonesQueryHandlerSuccess}
    ${'project'} | ${mockProjectMilestonesResponse} | ${milestonesQueryHandlerSuccess} | ${groupUsersQueryHandlerSuccess}
  `(
    'fetches $boardType milestones',
    async ({ boardType, mockedResponse, queryHandler, notCalledHandler }) => {
      createStore();
      createComponent({
        [queryHandler]: jest.fn().mockResolvedValue(mockedResponse),
        isProjectBoard: boardType === 'project',
        isGroupBoard: boardType === 'group',
      });

      findEditButton().vm.$emit('click');
      await waitForPromises();
      await nextTick();

      expect(queryHandler).toHaveBeenCalled();
      expect(notCalledHandler).not.toHaveBeenCalled();
    },
  );
});
