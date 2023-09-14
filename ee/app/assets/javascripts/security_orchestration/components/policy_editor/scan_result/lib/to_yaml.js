import { safeDump } from 'js-yaml';

/*
 Return yaml representation of a policy.
*/
export const toYaml = (policy) => {
  return safeDump(policy);
};
