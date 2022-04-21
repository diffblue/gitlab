import { memoize } from 'lodash';
import Api from '~/api';

const fetchGroupMembers = memoize((id) => Api.groupMembers(id).then((response) => response.data));

export const fetchUserIdsFromGroup = async (groupIdToInvite) => {
  const groupMembers = await fetchGroupMembers(groupIdToInvite);

  return groupMembers.map((user) => user.id);
};
