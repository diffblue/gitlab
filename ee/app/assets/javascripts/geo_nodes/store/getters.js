import { isNil } from 'lodash';
import { convertToCamelCase } from '~/lib/utils/text_utility';

export const verificationInfo = (state) => (id) => {
  const node = state.nodes.find((n) => n.id === id);
  const variables = {};

  if (node.primary) {
    variables.total = 'ChecksumTotalCount';
    variables.success = 'ChecksummedCount';
    variables.failed = 'ChecksumFailedCount';
  } else {
    variables.total = 'VerificationTotalCount';
    variables.success = 'VerifiedCount';
    variables.failed = 'VerificationFailedCount';
  }

  return state.replicableTypes
    .map((replicable) => {
      const camelCaseName = convertToCamelCase(replicable.namePlural);

      return {
        dataType: replicable.dataType,
        dataTypeTitle: replicable.dataTypeTitle,
        title: replicable.titlePlural,
        values: {
          total: node[`${camelCaseName}${variables.total}`],
          success: node[`${camelCaseName}${variables.success}`],
          failed: node[`${camelCaseName}${variables.failed}`],
        },
      };
    })
    .filter((replicable) =>
      Boolean(!isNil(replicable.values.success) || !isNil(replicable.values.failed)),
    );
};

export const syncInfo = (state) => (id) => {
  const node = state.nodes.find((n) => n.id === id);

  return state.replicableTypes.map((replicable) => {
    const camelCaseName = convertToCamelCase(replicable.namePlural);

    return {
      dataType: replicable.dataType,
      dataTypeTitle: replicable.dataTypeTitle,
      title: replicable.titlePlural,
      values: {
        total: node[`${camelCaseName}Count`],
        success: node[`${camelCaseName}SyncedCount`],
        failed: node[`${camelCaseName}FailedCount`],
      },
    };
  });
};

export const canRemoveNode = (state) => (id) => {
  const node = state.nodes.find((n) => n.id === id);

  return !node.primary || state.nodes.length === 1;
};
