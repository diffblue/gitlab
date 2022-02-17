import { safeLoad } from 'js-yaml';

/**
 * Checks for parameters unsupported by the scan result policy "Rule Mode"
 * @param {String} manifest YAML of scan result policy
 * @returns {Boolean} whether the YAML is valid to be parsed into "Rule Mode"
 */
const hasUnsupportedAttribute = (manifest) => {
  const primaryKeys = ['type', 'name', 'description', 'enabled', 'rules', 'actions'];
  const rulesKeys = [
    'type',
    'branches',
    'scanners',
    'vulnerabilities_allowed',
    'severity_levels',
    'vulnerability_states',
  ];
  const actionsKeys = [
    'type',
    'approvals_required',
    'user_approvers',
    'group_approvers',
    'user_approvers_ids',
    'group_approvers_ids',
  ];

  let isUnsupported = false;
  const hasInvalidKey = (object, allowedValues) => {
    return !Object.keys(object).every((item) => allowedValues.includes(item));
  };

  isUnsupported = hasInvalidKey(manifest, primaryKeys);

  if (manifest?.rules && !isUnsupported) {
    isUnsupported = manifest.rules.find((rule) => hasInvalidKey(rule, rulesKeys));
  }
  if (manifest?.actions && !isUnsupported) {
    isUnsupported = manifest.actions.find((action) => hasInvalidKey(action, actionsKeys));
  }

  return isUnsupported;
};

/*
  Construct a policy object expected by the policy editor from a yaml manifest.
*/
export const fromYaml = (manifest) => {
  const policy = safeLoad(manifest, { json: true });
  return hasUnsupportedAttribute(policy) ? { error: true } : policy;
};
