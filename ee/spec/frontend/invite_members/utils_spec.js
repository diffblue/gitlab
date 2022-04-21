import Api from '~/api';
import { fetchUserIdsFromGroup } from 'ee/invite_members/utils';

jest.mock('~/api.js', () => ({
  groupMembers: jest.fn().mockResolvedValue({ data: [{ id: 123 }, { id: 256 }] }),
}));

describe('fetchUserIdsFromGroup', () => {
  it('caches the response for the same input', async () => {
    await fetchUserIdsFromGroup(1);
    await fetchUserIdsFromGroup(1);
    expect(Api.groupMembers).toHaveBeenCalledTimes(1);
  });

  it('returns ids of the users in the group', async () => {
    const result = await fetchUserIdsFromGroup(1);
    expect(result).toEqual([123, 256]);
  });
});
