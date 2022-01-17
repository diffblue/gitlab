import { safeLoad } from 'js-yaml';

/*
  Construct a policy object expected by the policy editor from a yaml manifest.
*/
export const fromYaml = (manifest) => {
  return safeLoad(manifest, { json: true });
};
