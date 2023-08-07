import { safeLoad } from 'js-yaml';
import { isValidPolicy, hasInvalidCron } from '../../utils';
import {
  BRANCH_TYPE_KEY,
  RULE_MODE_SCANNERS,
  VALID_SCAN_EXECUTION_BRANCH_TYPE_OPTIONS,
} from '../../constants';

/**
 * Check if any rule has invalid branch type
 * @param rules list of rules with either branches or branch_type property
 * @returns {Boolean}
 */
const hasInvalidBranchType = (rules) => {
  if (!rules) return false;

  return rules.some(
    (rule) =>
      BRANCH_TYPE_KEY in rule &&
      !VALID_SCAN_EXECUTION_BRANCH_TYPE_OPTIONS.includes(rule.branch_type),
  );
};

/**
 * Checks if rule mode supports the inputted scanner
 * @param {Object} policy
 * @returns {Boolean} if all inputted scanners are in the available scanners dictionary
 */
export const hasRuleModeSupportedScanners = (policy) => {
  /**
   * If policy has no actions just return as valid
   */
  if (!policy?.actions) {
    return true;
  }

  const availableScanners = Object.keys(RULE_MODE_SCANNERS);
  const configuredScanners = policy.actions.map((action) => action.scan);
  return configuredScanners.every((scanner) => availableScanners.includes(scanner));
};

/*
  Construct a policy object expected by the policy editor from a yaml manifest.
*/
export const fromYaml = ({ manifest, validateRuleMode = false, glFeatures = {} }) => {
  try {
    const policy = safeLoad(manifest, { json: true });

    if (validateRuleMode) {
      /**
       * These values are what is supported by rule mode. If the yaml has any other values,
       * rule mode will be disabled. This validation should not be used to check whether
       * the yaml is a valid policy; that should be done on the backend with the official
       * schema. These values should not be retrieved from the backend schema because
       * the UI for new attributes may not be available.
       */
      const rulesKeys = [
        'type',
        'agents',
        'branches',
        'branch_type',
        'cadence',
        'timezone',
        ...(glFeatures.securityPoliciesBranchExceptions ? ['branch_exceptions'] : []),
      ];
      const actionsKeys = ['scan', 'site_profile', 'scanner_profile', 'variables', 'tags'];

      return isValidPolicy({ policy, rulesKeys, actionsKeys }) &&
        !hasInvalidCron(policy) &&
        !hasInvalidBranchType(policy.rules) &&
        hasRuleModeSupportedScanners(policy)
        ? policy
        : { error: true };
    }

    return policy;
  } catch {
    /**
     * Catch parsing error of safeLoad
     */
    return { error: true, key: 'yaml-parsing' };
  }
};

/**
 * Converts a security policy from yaml to an object
 * @param {String} manifest a security policy in yaml form
 * @param {Object} glFeatures check if flag is anbled
 * @returns {Object} security policy object and any errors
 */
export const createPolicyObject = (manifest, glFeatures = {}) => {
  const policy = fromYaml({ manifest, validateRuleMode: true, glFeatures });

  return { policy, hasParsingError: Boolean(policy.error) };
};
