import MockAdapter from 'axios-mock-adapter';
import { LEGACY_TABLE_COLUMNS } from 'ee/analytics/contribution_analytics/constants';
import GroupMembers from 'ee/analytics/contribution_analytics/group_members';
import { createAlert } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';

import { MOCK_MEMBERS, CONTRIBUTIONS_PATH } from './mock_data';

jest.mock('~/flash');

describe('GroupMembers', () => {
  let store;

  beforeEach(() => {
    store = new GroupMembers(CONTRIBUTIONS_PATH);
  });

  afterEach(() => {
    createAlert.mockClear();
  });

  describe('setColumns', () => {
    beforeEach(() => {
      store.setColumns(LEGACY_TABLE_COLUMNS);
    });

    it('sets columns to store state', () => {
      expect(store.state.columns).toBe(LEGACY_TABLE_COLUMNS);
    });

    it('initializes sortOrders on store state', () => {
      Object.keys(store.state.sortOrders).forEach((column) => {
        expect(store.state.sortOrders[column]).toBe(1);
      });
    });
  });

  describe('setMembers', () => {
    it('sets members to store state', () => {
      store.setMembers(MOCK_MEMBERS);

      expect(store.state.members).toHaveLength(MOCK_MEMBERS.length);
    });
  });

  describe('sortMembers', () => {
    it('sorts members list based on provided column name', () => {
      store.setColumns(LEGACY_TABLE_COLUMNS);
      store.setMembers(MOCK_MEMBERS);

      let [firstMember] = store.state.members;

      expect(firstMember.fullname).toBe('Administrator');

      store.sortMembers('fullname');
      [firstMember] = store.state.members;

      expect(firstMember.fullname).toBe('Terrell Graham');
    });
  });

  describe('fetchContributedMembers', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    it('calls service.getContributedMembers and sets response to the store on success', async () => {
      mock.onGet(CONTRIBUTIONS_PATH).reply(HTTP_STATUS_OK, MOCK_MEMBERS);
      jest.spyOn(store, 'setColumns').mockImplementation(() => {});
      jest.spyOn(store, 'setMembers').mockImplementation(() => {});

      store.fetchContributedMembers();
      expect(store.isLoading).toBe(true);

      await waitForPromises();
      expect(store.isLoading).toBe(false);
      expect(store.setColumns).toHaveBeenCalledWith(expect.any(Object));
      expect(store.setMembers).toHaveBeenCalledWith(MOCK_MEMBERS);
    });

    it('calls service.getContributedMembers and sets `isLoading` to false and shows flash message if request failed', async () => {
      mock.onGet(CONTRIBUTIONS_PATH).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});

      await expect(store.fetchContributedMembers()).rejects.toEqual(
        new Error('Request failed with status code 500'),
      );
      expect(store.isLoading).toBe(false);
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while fetching group member contributions',
      });
    });
  });
});
