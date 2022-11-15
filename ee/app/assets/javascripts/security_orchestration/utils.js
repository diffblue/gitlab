import createGqClient from '~/lib/graphql';
import { POLICY_TYPE_COMPONENT_OPTIONS } from './components/constants';

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
