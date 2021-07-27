import MockAdapter from 'axios-mock-adapter';
import * as GroupsApi from 'ee/api/groups_api';
import { DEFAULT_PER_PAGE } from '~/api';
import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';

describe('GroupsApi', () => {
  const dummyApiVersion = 'v3000';
  const dummyUrlRoot = '/gitlab';
  const dummyGon = {
    api_version: dummyApiVersion,
    relative_url_root: dummyUrlRoot,
  };

  let originalGon;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    originalGon = window.gon;
    window.gon = { ...dummyGon };
  });

  afterEach(() => {
    mock.restore();
    window.gon = originalGon;
  });

  describe('Billable members list', () => {
    const namespaceId = 1000;

    describe('fetchBillableGroupMembersList', () => {
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${namespaceId}/billable_members`;

      it('GETs the right url', async () => {
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(httpStatus.OK, []);

        const { data } = await GroupsApi.fetchBillableGroupMembersList(namespaceId);

        expect(data).toEqual([]);
        expect(axios.get).toHaveBeenCalledWith(expectedUrl, {
          params: { page: 1, per_page: DEFAULT_PER_PAGE },
        });
      });
    });

    describe('fetchBillableGroupMemberMemberships', () => {
      const memberId = 2;
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${namespaceId}/billable_members/${memberId}/memberships`;

      it('fetches memberships for the member', async () => {
        jest.spyOn(axios, 'get');
        mock.onGet(expectedUrl).replyOnce(httpStatus.OK, []);

        const { data } = await GroupsApi.fetchBillableGroupMemberMemberships(namespaceId, memberId);

        expect(data).toEqual([]);
        expect(axios.get).toHaveBeenCalledWith(expectedUrl);
      });
    });

    describe('removeBillableMemberFromGroup', () => {
      const memberId = 2;
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${namespaceId}/billable_members/${memberId}`;

      it('removes a billable member from a group', async () => {
        jest.spyOn(axios, 'delete');
        mock.onDelete(expectedUrl).replyOnce(httpStatus.OK, []);

        const { data } = await GroupsApi.removeBillableMemberFromGroup(namespaceId, memberId);

        expect(data).toEqual([]);
        expect(axios.delete).toHaveBeenCalledWith(expectedUrl);
      });
    });
  });
});
