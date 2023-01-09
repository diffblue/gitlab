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
    .filter(({ verificationEnabled }) => verificationEnabled)
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
    });
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

export const dataTypes = (state) => {
  return state.replicableTypes.reduce((acc, replicable) => {
    if (acc.some((type) => type.dataType === replicable.dataType)) {
      return acc;
    }

    return [
      ...acc,
      {
        dataType: replicable.dataType,
        dataTypeTitle: replicable.dataTypeTitle,
      },
    ];
  }, []);
};

export const replicationCountsByDataTypeForNode = (_, getters) => (id) => {
  const syncInfoData = getters.syncInfo(id);
  const verificationInfoData = getters.verificationInfo(id);

  return getters.dataTypes.map(({ dataType, dataTypeTitle }) => {
    return {
      title: dataTypeTitle,
      sync: syncInfoData
        .filter((replicable) => replicable.dataType === dataType)
        .map((d) => d.values),
      verification: verificationInfoData
        .filter((replicable) => replicable.dataType === dataType)
        .map((d) => d.values),
    };
  });
};

export const canRemoveNode = (state) => (id) => {
  const node = state.nodes.find((n) => n.id === id);

  return !node.primary || state.nodes.length === 1;
};

const filterByStatus = (status) => {
  if (!status) {
    return () => true;
  }

  // If the healthStatus is not falsey, we group that as status "unknown"
  return (n) => (n.healthStatus ? n.healthStatus.toLowerCase() === status : status === 'unknown');
};

const filterBySearch = (search) => {
  if (!search) {
    return () => true;
  }

  return (n) =>
    n.name?.toLowerCase().includes(search.toLowerCase()) ||
    n.url?.toLowerCase().includes(search.toLowerCase());
};

export const filteredNodes = (state) => {
  return state.nodes
    .filter(filterByStatus(state.statusFilter))
    .filter(filterBySearch(state.searchFilter));
};

export const countNodesForStatus = (state) => (status) => {
  return state.nodes.filter(filterByStatus(status)).length;
};
