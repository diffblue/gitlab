import { DEFAULT_PER_PAGE } from '~/api';
import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';

const GROUPS_BILLABLE_MEMBERS_SINGLE_PATH = '/api/:version/groups/:group_id/billable_members/:id';
const GROUPS_BILLABLE_MEMBERS_PATH = '/api/:version/groups/:id/billable_members';
const GROUPS_BILLABLE_MEMBERS_SINGLE_MEMBERSHIPS_PATH =
  '/api/:version/groups/:group_id/billable_members/:member_id/memberships';

export const fetchBillableGroupMembersList = (namespaceId, options = {}) => {
  const url = buildApiUrl(GROUPS_BILLABLE_MEMBERS_PATH).replace(':id', namespaceId);
  const defaults = {
    per_page: DEFAULT_PER_PAGE,
    page: 1,
  };

  return axios.get(url, {
    params: {
      ...defaults,
      ...options,
    },
  });
};

export const fetchBillableGroupMemberMemberships = (namespaceId, memberId) => {
  const url = buildApiUrl(GROUPS_BILLABLE_MEMBERS_SINGLE_MEMBERSHIPS_PATH)
    .replace(':group_id', namespaceId)
    .replace(':member_id', memberId);

  return axios.get(url);
};

export const removeBillableMemberFromGroup = (groupId, memberId) => {
  const url = buildApiUrl(GROUPS_BILLABLE_MEMBERS_SINGLE_PATH)
    .replace(':group_id', groupId)
    .replace(':id', memberId);

  return axios.delete(url);
};
