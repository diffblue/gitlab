import { registerSchema } from '~/ide/utils';
import { getSchemaUrl, getSinglePolicySchema } from './utils';

export class PolicySchemaExtension {
  static get extensionName() {
    return 'SecurityPolicySchema';
  }
  // eslint-disable-next-line class-methods-use-this
  provides() {
    return {
      registerSecurityPolicySchema: async (instance, options) => {
        const { namespacePath, namespaceType, policyType } = options;
        const singlePolicySchema = await getSinglePolicySchema({
          namespacePath,
          namespaceType,
          policyType,
        });
        const modelFileName = instance.getModel().uri.path.split('/').pop();

        registerSchema({
          uri: getSchemaUrl({ namespacePath, namespaceType }),
          schema: singlePolicySchema,
          fileMatch: [modelFileName],
        });
      },
    };
  }
}
