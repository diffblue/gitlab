import axios from '~/lib/utils/axios_utils';
import { buildApiUrl } from '~/api/api_utils';

const MEMBER_ROLES_PATH = '/api/:version/groups/:id/member_roles';
const DELETE_MEMBER_ROLES_PATH = '/api/:version/groups/:id/member_roles/:member_role_id';

/**
 * Creates a new member role on a group (groupId).
 * @param {string} groupId
 * @param {object} data
 */
export function createMemberRole(groupId, data) {
  const url = buildApiUrl(MEMBER_ROLES_PATH.replace(':id', groupId));

  return axios.post(url, data);
}

/**
 * Fetches all the member roles associated to a group (groupId).
 * @param {string} groupId
 */
export function getMemberRoles(groupId) {
  const url = buildApiUrl(MEMBER_ROLES_PATH.replace(':id', groupId));

  return axios.get(url);
}

/**
 * Deletes the member role (roleId) associated to a group (groupId).
 * @param {string} groupId
 * @param {string} roleId
 */
export function deleteMemberRole(groupId, roleId) {
  const url = buildApiUrl(
    DELETE_MEMBER_ROLES_PATH.replace(':id', groupId).replace(':member_role_id', roleId),
  );

  return axios.delete(url);
}
