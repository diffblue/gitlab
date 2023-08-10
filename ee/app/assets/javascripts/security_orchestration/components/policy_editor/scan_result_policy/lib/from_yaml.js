import { safeLoad } from 'js-yaml';
import { isValidPolicy } from '../../utils';
import { PRIMARY_POLICY_KEYS } from '../../constants';

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
      const primaryKeys = [
        ...PRIMARY_POLICY_KEYS,
        ...(glFeatures?.scanResultPolicySettings ? [`approval_settings`] : []),
      ];
      const rulesKeys = [
        'type',
        'branches',
        'branch_type',
        'branch_exceptions',
        'license_states',
        'license_types',
        'match_on_inclusion',
        'scanners',
        'severity_levels',
        'vulnerabilities_allowed',
        'vulnerability_states',
        'vulnerability_age',
      ];
      const actionsKeys = [
        'type',
        'approvals_required',
        'user_approvers',
        'group_approvers',
        'user_approvers_ids',
        'group_approvers_ids',
        'role_approvers',
      ];

      return isValidPolicy({ policy, primaryKeys, rulesKeys, actionsKeys })
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
 * @returns {Object} security policy object and any errors
 */
export const createPolicyObject = (manifest, glFeatures = {}) => {
  const policy = fromYaml({ manifest, validateRuleMode: true, glFeatures });

  return { policy, hasParsingError: Boolean(policy.error) };
};
