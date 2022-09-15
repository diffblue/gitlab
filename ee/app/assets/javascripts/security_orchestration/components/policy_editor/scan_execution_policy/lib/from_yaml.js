import { safeLoad } from 'js-yaml';
import { isValidPolicy } from '../../utils';

/*
  Construct a policy object expected by the policy editor from a yaml manifest.
*/
export const fromYaml = (manifest) => {
  const policy = safeLoad(manifest, { json: true });

  // TODO dynamically request these as part of https://gitlab.com/gitlab-org/gitlab/-/issues/369007
  const primaryKeys = ['type', 'name', 'description', 'enabled', 'rules', 'actions'];
  const rulesKeys = ['type', 'branches', 'cadence'];
  const actionsKeys = ['scan', 'site_profile', 'scanner_profile', 'variables'];

  return isValidPolicy({ policy, primaryKeys, rulesKeys, actionsKeys }) ? policy : { error: true };
};
