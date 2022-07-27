import { registerSchema } from '~/ide/utils';
import { NAMESPACE_TYPES } from '../constants';
import { getSchemaUrl, getSingleScanExecutionPolicySchema } from './utils';
import { POLICY_TYPE_COMPONENT_OPTIONS } from './constants';

const SCHEMA_DICT = {
  [POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.urlParameter]: {
    [NAMESPACE_TYPES.PROJECT]: getSingleScanExecutionPolicySchema,
    [NAMESPACE_TYPES.GROUP]: getSingleScanExecutionPolicySchema,
  },
};

export class PolicySchemaExtension {
  static get extensionName() {
    return 'SecurityPolicySchema';
  }
  // eslint-disable-next-line class-methods-use-this
  provides() {
    return {
      registerSecurityPolicySchema: async (instance, options) => {
        const { namespacePath, namespaceType, policyType } = options;
        if (SCHEMA_DICT[policyType]?.[namespaceType]) {
          const singlePolicySchema = await SCHEMA_DICT[policyType][namespaceType]({
            namespacePath,
            namespaceType,
          });
          const modelFileName = instance.getModel().uri.path.split('/').pop();

          registerSchema({
            uri: getSchemaUrl({ namespacePath, namespaceType }),
            schema: singlePolicySchema,
            fileMatch: [modelFileName],
          });
        }
      },
    };
  }
}
