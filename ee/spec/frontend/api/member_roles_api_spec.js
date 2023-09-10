import MockAdapter from 'axios-mock-adapter';
import { createMemberRole, deleteMemberRole, getMemberRoles } from 'ee/api/member_roles_api';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('member_roles_api.js', () => {
  let mockAxios;

  beforeEach(() => {
    window.gon = { api_version: 'v4' };
    mockAxios = new MockAdapter(axios);
  });

  describe('createMemberRole', () => {
    const data = {
      base_access_level: '10',
      name: 'My name',
      description: 'My description',
      read_code: 1,
    };
    beforeEach(() => {
      mockAxios.onPost('/api/v4/groups/4/member_roles').replyOnce(HTTP_STATUS_OK);
    });

    it('posts data to create a new member role', async () => {
      expect(mockAxios.history.post).toHaveLength(0);

      await createMemberRole('4', data);

      expect(mockAxios.history.post[0].data).toBe(JSON.stringify(data));
    });
  });

  describe('getMemberRoles', () => {
    beforeEach(() => {
      mockAxios.onGet('/api/v4/groups/4/member_roles').replyOnce(HTTP_STATUS_OK);
    });

    it('fetches member roles', async () => {
      expect(mockAxios.history.get).toHaveLength(0);

      await getMemberRoles('4');

      expect(mockAxios.history.get).toHaveLength(1);
    });
  });

  describe('deleteMemberRole', () => {
    beforeEach(() => {
      mockAxios.onDelete('/api/v4/groups/4/member_roles/8').replyOnce(HTTP_STATUS_OK);
    });

    it('fetches member roles', async () => {
      expect(mockAxios.history.delete).toHaveLength(0);

      await deleteMemberRole('4', '8');

      expect(mockAxios.history.delete).toHaveLength(1);
    });
  });
});
