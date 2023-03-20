import axios from '~/lib/utils/axios_utils';
import { getBaseURL, joinPaths } from '~/lib/utils/url_utility';
import { NAMESPACE_TYPES } from '../constants';

export const getPolicyListUrl = ({ namespacePath, namespaceType = NAMESPACE_TYPES.GROUP }) => {
  const isGroup = namespaceType === NAMESPACE_TYPES.GROUP;
  return joinPaths(
    getBaseURL(),
    isGroup ? 'groups' : '',
    namespacePath,
    '-',
    'security',
    'policies',
  );
};

export const getSchemaUrl = ({ namespacePath, namespaceType }) => {
  const policyListUrl = getPolicyListUrl({ namespacePath, namespaceType });
  return joinPaths(policyListUrl, 'schema');
};

export const isPolicyInherited = (source) => {
  if (source?.inherited === true) {
    return true;
  }

  return false;
};

export const getSinglePolicySchema = async ({ namespacePath, namespaceType, policyType }) => {
  try {
    const { data: schemaForMultiplePolicies } = await axios.get(
      getSchemaUrl({ namespacePath, namespaceType }),
    );
    return {
      $id: schemaForMultiplePolicies.$id,
      title: schemaForMultiplePolicies.title,
      description: schemaForMultiplePolicies.description,
      type: schemaForMultiplePolicies.type,
      properties: {
        type: {
          type: 'string',
          // eslint-disable-next-line @gitlab/require-i18n-strings
          description: 'Specifies the type of policy to be enforced.',
          enum: policyType,
        },
        ...schemaForMultiplePolicies.properties[policyType].items.properties,
      },
    };
  } catch {
    return {};
  }
};
