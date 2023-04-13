import { GlTokenSelector } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';

import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import getUsersByUserIdsOrUsernames from 'ee/graphql_shared/queries/get_users_by_user_ids_or_usernames.query.graphql';
import searchUsersQuery from '~/graphql_shared/queries/users_search_all.query.graphql';
import searchGroupUsersQuery from '~/graphql_shared/queries/group_users_search.query.graphql';

import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

import UsersSelect from 'ee/admin/application_settings/reporting/git_abuse_settings/components/users_select.vue';
import { SEARCH_TERM_TOO_SHORT } from 'ee/admin/application_settings/reporting/git_abuse_settings/constants';

import {
  getUsersResponse,
  searchUsersResponse,
  groupMembersResponse,
  mockUser1,
  mockUser2,
} from '../mock_data';

Vue.use(VueApollo);

describe('Users Select component', () => {
  let wrapper;
  let fakeApollo;

  const findUserSelector = () => wrapper.findComponent(GlTokenSelector);
  const findUserSelectorInput = () => findUserSelector().find('input[type="text"]');
  const findUserSelectorDropdown = () => findUserSelector().find('[role="menu"]');

  const setUserSelectorInputValue = (value) => {
    const searchInput = findUserSelectorInput();

    searchInput.element.value = value;
    searchInput.trigger('input');

    return nextTick();
  };

  const getQueryHandlerSuccess = jest.fn().mockResolvedValue(getUsersResponse);
  const searchQueryHandlerSuccess = jest.fn().mockResolvedValue(searchUsersResponse);
  const searchGroupQueryHandlerSuccess = jest.fn().mockResolvedValue(groupMembersResponse);

  const createComponent = ({ props, provide } = { props: {}, provide: {} }) => {
    fakeApollo = createMockApollo([
      [getUsersByUserIdsOrUsernames, getQueryHandlerSuccess],
      [searchUsersQuery, searchQueryHandlerSuccess],
      [searchGroupUsersQuery, searchGroupQueryHandlerSuccess],
    ]);

    wrapper = mount(UsersSelect, {
      apolloProvider: fakeApollo,
      provide,
      propsData: {
        inputId: 'exluded-users',
        selected: [],
        ...props,
      },
    });
  };

  afterEach(() => {
    fakeApollo = null;
  });

  describe('When component loads', () => {
    beforeEach(() => {
      createComponent({ props: { inputId: 'alerted-users' } });
    });

    it('renders token-selector', () => {
      expect(findUserSelector().exists()).toBe(true);
      expect(findUserSelector().props('textInputAttrs')).toEqual({ id: 'alerted-users' });
    });
  });

  describe('When there are no users already saved', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('does not run the apollo query to get users', () => {
      expect(getQueryHandlerSuccess).not.toHaveBeenCalled();
    });
  });

  describe('When there are users saved', () => {
    beforeEach(async () => {
      createComponent({ props: { selected: [mockUser1.username, 'xxx'] } });

      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
      await waitForPromises();
    });

    it('gets users by usernames and sets selectedTokens', () => {
      expect(getQueryHandlerSuccess).toHaveBeenCalled();
      expect(searchQueryHandlerSuccess).toHaveBeenCalled();

      expect(findUserSelector().props('loading')).toEqual(false);
      expect(findUserSelector().props('dropdownItems')).toHaveLength(2);

      expect(findUserSelector().props('selectedTokens')).toHaveLength(1);
      expect(findUserSelector().props('selectedTokens')[0]).toEqual(mockUser1);
    });

    it('emits a selection-changed event with only users from the result', () => {
      expect(wrapper.emitted('selection-changed')[0][0]).toEqual([mockUser1.username]);
    });
  });

  describe('When searching for users', () => {
    beforeEach(async () => {
      createComponent({ props: { selected: [mockUser1.username] } });

      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
      await waitForPromises();
    });

    it('renders search term is too short message when it is less than 3 characters', async () => {
      await setUserSelectorInputValue('us');
      expect(findUserSelectorDropdown().text()).toBe(SEARCH_TERM_TOO_SHORT);
      expect(findUserSelector().props('dropdownItems')).toHaveLength(0);
    });

    it('renders users when search term is 3 characters or more', async () => {
      await setUserSelectorInputValue('user');
      expect(findUserSelectorDropdown().text()).toContain(mockUser2.username);
    });
  });

  describe('When selecting users by ID', () => {
    beforeEach(async () => {
      createComponent({ props: { selectByUsername: false, selected: [1, 44] } });

      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
      await waitForPromises();
    });

    it('emits a selection-changed event with only users from the result', () => {
      expect(wrapper.emitted('selection-changed')[0][0]).toEqual([1]);
    });
  });

  describe('When groupFullPath is present', () => {
    const GROUP_FULL_PATH = 'group-full-path';

    beforeEach(async () => {
      createComponent({ provide: { groupFullPath: GROUP_FULL_PATH } });

      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
      await waitForPromises();
    });

    it('renders list of users that are members of the group', () => {
      expect(searchGroupQueryHandlerSuccess).toHaveBeenCalledWith({
        search: '',
        first: 20,
        fullPath: GROUP_FULL_PATH,
      });

      expect(findUserSelector().props('loading')).toEqual(false);
      expect(findUserSelector().props('dropdownItems')).toHaveLength(2);
    });
  });
});
