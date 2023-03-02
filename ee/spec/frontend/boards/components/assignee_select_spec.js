import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';

import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import AssigneeSelect from 'ee/boards/components/assignee_select.vue';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';

import { boardObj } from 'jest/boards/mock_data';
import { projectMembersResponse, groupMembersResponse, mockUser2 } from 'jest/sidebar/mock_data';

import searchGroupUsersQuery from '~/graphql_shared/queries/group_users_search.query.graphql';
import searchProjectUsersQuery from '~/graphql_shared/queries/users_search.query.graphql';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import DropdownWidget from '~/vue_shared/components/dropdown/dropdown_widget/dropdown_widget.vue';

Vue.use(VueApollo);
Vue.use(Vuex);

describe('Assignee select component', () => {
  let wrapper;
  let fakeApollo;
  let store;

  const selectedText = () => wrapper.find('[data-testid="selected-assignee"]').text();
  const findEditButton = () => wrapper.findComponent(GlButton);
  const findDropdown = () => wrapper.findComponent(DropdownWidget);

  const usersQueryHandlerSuccess = jest.fn().mockResolvedValue(projectMembersResponse);
  const groupUsersQueryHandlerSuccess = jest.fn().mockResolvedValue(groupMembersResponse);

  const createStore = () => {
    store = new Vuex.Store({
      actions: {
        setError: jest.fn(),
      },
    });
  };

  const createComponent = ({
    props = {},
    usersQueryHandler = usersQueryHandlerSuccess,
    isGroupBoard = false,
    isProjectBoard = false,
  } = {}) => {
    fakeApollo = createMockApollo([
      [searchProjectUsersQuery, usersQueryHandler],
      [searchGroupUsersQuery, groupUsersQueryHandlerSuccess],
    ]);
    wrapper = shallowMount(AssigneeSelect, {
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
    it('defaults to Any Assignee', () => {
      expect(selectedText()).toContain('Any assignee');
    });

    it('skips the queries and does not render dropdown', () => {
      expect(usersQueryHandlerSuccess).not.toHaveBeenCalled();
      expect(findDropdown().isVisible()).toBe(false);
    });

    it('renders selected assignee', async () => {
      findEditButton().vm.$emit('click');
      await waitForPromises();
      findDropdown().vm.$emit('set-option', mockUser2);

      await nextTick();
      expect(selectedText()).toContain(mockUser2.username);
    });
  });

  describe('when editing', () => {
    it('trigger query and renders dropdown with returned users', async () => {
      findEditButton().vm.$emit('click');
      await waitForPromises();
      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
      await waitForPromises();
      expect(usersQueryHandlerSuccess).toHaveBeenCalled();

      expect(findDropdown().isVisible()).toBe(true);
      expect(findDropdown().props('options')).toHaveLength(3);
      expect(findDropdown().props('presetOptions')).toHaveLength(1);
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
    boardType    | mockedResponse            | queryHandler                     | notCalledHandler
    ${'group'}   | ${groupMembersResponse}   | ${groupUsersQueryHandlerSuccess} | ${usersQueryHandlerSuccess}
    ${'project'} | ${projectMembersResponse} | ${usersQueryHandlerSuccess}      | ${groupUsersQueryHandlerSuccess}
  `(
    'fetches $boardType users',
    async ({ boardType, mockedResponse, queryHandler, notCalledHandler }) => {
      createStore();
      createComponent({
        [queryHandler]: jest.fn().mockResolvedValue(mockedResponse),
        isProjectBoard: boardType === 'project',
        isGroupBoard: boardType === 'group',
      });

      findEditButton().vm.$emit('click');
      await waitForPromises();
      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
      await nextTick();

      expect(queryHandler).toHaveBeenCalled();
      expect(notCalledHandler).not.toHaveBeenCalled();
    },
  );
});
