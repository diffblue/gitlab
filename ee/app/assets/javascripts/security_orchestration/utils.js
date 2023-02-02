import createGqClient from '~/lib/graphql';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_GROUP, TYPENAME_USER } from '~/graphql_shared/constants';
import { POLICY_TYPE_COMPONENT_OPTIONS } from './components/constants';
import { GROUP_TYPE, USER_TYPE } from './constants';

/**
 * Get a policy's type
 * @param {String} typeName policy's YAML manifest
 * @returns {String|null} policy type if available
 */
export const getPolicyType = (typeName = '') => {
  return Object.values(POLICY_TYPE_COMPONENT_OPTIONS).find(
    (component) => component.typeName === typeName,
  )?.value;
};

// TODO rename this method to `decomposeApprovers` with the removal of the `:scan_result_role_action` feature flag (https://gitlab.com/gitlab-org/gitlab/-/issues/377866)
/**
 * Separate existing approvers by type
 * @param {Array} existingApprovers all approvers
 * @returns {Object} approvers separated by type
 */
export const decomposeApproversV2 = (existingApprovers) => {
  // TODO remove groupUniqKeys with the removal of the `:scan_result_role_action` feature flag (https://gitlab.com/gitlab-org/gitlab/-/issues/377866)
  const GROUP_TYPE_UNIQ_KEY = 'full_name';
  const GROUP_TYPE_UNIQ_KEY_V2 = 'fullName';

  return existingApprovers.reduce(
    (acc, approver) => {
      const approverKeys = Object.keys(approver);

      let type = USER_TYPE;
      let value = convertToGraphQLId(TYPENAME_USER, approver.id);

      if (
        approverKeys.includes(GROUP_TYPE_UNIQ_KEY) ||
        approverKeys.includes(GROUP_TYPE_UNIQ_KEY_V2)
      ) {
        type = GROUP_TYPE;
        value = convertToGraphQLId(TYPENAME_GROUP, approver.id);
      }

      acc[type].push({
        ...approver,
        type,
        value,
      });

      return acc;
    },
    { [GROUP_TYPE]: [], [USER_TYPE]: [] },
  );
};

/**
 * Removes inital line dashes from a policy YAML that is received from the API, which
 * is not required for the user.
 * @param {String} manifest the policy from the API request
 * @returns {String} the policy without the initial dashes or the initial string
 */
export const removeUnnecessaryDashes = (manifest) => {
  return manifest.replace('---\n', '');
};

/**
 * Create GraphQL Client for threat monitoring
 */
export const gqClient = createGqClient();
