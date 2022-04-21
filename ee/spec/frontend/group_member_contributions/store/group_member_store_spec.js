import MockAdapter from 'axios-mock-adapter';
import defaultColumns from 'ee/group_member_contributions/constants';
import GroupMemberStore from 'ee/group_member_contributions/store/group_member_store';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';

import { rawMembers, contributionsPath } from '../mock_data';

jest.mock('~/flash');

describe('GroupMemberStore', () => {
  let store;

  beforeEach(() => {
    store = new GroupMemberStore(contributionsPath);
  });

  afterEach(() => {
    createFlash.mockClear();
  });

  describe('setColumns', () => {
    beforeEach(() => {
      store.setColumns(defaultColumns);
    });

    it('sets columns to store state', () => {
      expect(store.state.columns).toBe(defaultColumns);
    });

    it('initializes sortOrders on store state', () => {
      Object.keys(store.state.sortOrders).forEach((column) => {
        expect(store.state.sortOrders[column]).toBe(1);
      });
    });
  });

  describe('setMembers', () => {
    it('sets members to store state', () => {
      store.setMembers(rawMembers);

      expect(store.state.members).toHaveLength(rawMembers.length);
    });
  });

  describe('sortMembers', () => {
    it('sorts members list based on provided column name', () => {
      store.setColumns(defaultColumns);
      store.setMembers(rawMembers);

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
      mock.onGet(contributionsPath).reply(200, rawMembers);
      jest.spyOn(store, 'setColumns').mockImplementation(() => {});
      jest.spyOn(store, 'setMembers').mockImplementation(() => {});

      expect(store.isLoading).toBe(true);
      await store.fetchContributedMembers();

      expect(store.isLoading).toBe(false);
      expect(store.setColumns).toHaveBeenCalledWith(expect.any(Object));
      expect(store.setMembers).toHaveBeenCalledWith(rawMembers);
    });

    it('calls service.getContributedMembers and sets `isLoading` to false and shows flash message if request failed', async () => {
      mock.onGet(contributionsPath).reply(500, {});

      await expect(store.fetchContributedMembers()).rejects.toEqual(
        new Error('Request failed with status code 500'),
      );
      expect(store.isLoading).toBe(false);
      expect(createFlash).toHaveBeenCalledWith({
        message: 'Something went wrong while fetching group member contributions',
      });
    });
  });
});
