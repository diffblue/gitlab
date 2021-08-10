import createGqClient from '~/lib/graphql';
import { POLICY_TYPE_COMPONENT_OPTIONS } from './components/constants';

/**
 * Get the height of the wrapper page element
 * This height can be used to determine where the highest element goes in a page
 * Useful for gl-drawer's header-height prop
 * @param {String} class the content wrapper class
 * @returns {String} height in px
 */
export const getContentWrapperHeight = (contentWrapperClass) => {
  const wrapperEl = document.querySelector(contentWrapperClass);
  return wrapperEl ? `${wrapperEl.offsetTop}px` : '';
};

/**
 * Get a policy's type
 * @param {String} yaml policy's YAML manifest
 * @returns {String|null} policy type if available
 */
export const getPolicyType = (yaml = '') => {
  if (yaml?.includes(POLICY_TYPE_COMPONENT_OPTIONS.container.yamlIndicator)) {
    return POLICY_TYPE_COMPONENT_OPTIONS.container.value;
  }
  if (yaml?.includes(POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.yamlIndicator)) {
    return POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.value;
  }
  return null;
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
