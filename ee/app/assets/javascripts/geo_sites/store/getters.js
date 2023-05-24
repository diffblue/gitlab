import { convertToCamelCase } from '~/lib/utils/text_utility';

export const sortedReplicableTypes = (state) => {
  const replicableTypes = [...state.replicableTypes];

  replicableTypes.sort((a, b) => {
    if (a.dataTypeSortOrder === b.dataTypeSortOrder) {
      return a.name.localeCompare(b.name);
    }

    return a.dataTypeSortOrder - b.dataTypeSortOrder;
  });

  return replicableTypes;
};

export const verificationInfo = (state, getters) => (id) => {
  const site = state.sites.find((n) => n.id === id);
  const variables = {};

  if (site.primary) {
    variables.total = 'ChecksumTotalCount';
    variables.success = 'ChecksummedCount';
    variables.failed = 'ChecksumFailedCount';
  } else {
    variables.total = 'VerificationTotalCount';
    variables.success = 'VerifiedCount';
    variables.failed = 'VerificationFailedCount';
  }

  return getters.sortedReplicableTypes
    .filter(({ verificationEnabled }) => verificationEnabled)
    .map((replicable) => {
      const camelCaseName = convertToCamelCase(replicable.namePlural);

      return {
        dataType: replicable.dataType,
        dataTypeTitle: replicable.dataTypeTitle,
        title: replicable.titlePlural,
        values: {
          total: site[`${camelCaseName}${variables.total}`],
          success: site[`${camelCaseName}${variables.success}`],
          failed: site[`${camelCaseName}${variables.failed}`],
        },
      };
    });
};

export const syncInfo = (state, getters) => (id) => {
  const site = state.sites.find((n) => n.id === id);

  return getters.sortedReplicableTypes.map((replicable) => {
    const camelCaseName = convertToCamelCase(replicable.namePlural);

    return {
      dataType: replicable.dataType,
      dataTypeTitle: replicable.dataTypeTitle,
      title: replicable.titlePlural,
      values: {
        total: site[`${camelCaseName}Count`],
        success: site[`${camelCaseName}SyncedCount`],
        failed: site[`${camelCaseName}FailedCount`],
      },
    };
  });
};

export const dataTypes = (_, getters) => {
  return getters.sortedReplicableTypes.reduce((acc, replicable) => {
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

export const replicationCountsByDataTypeForSite = (_, getters) => (id) => {
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

export const canRemoveSite = (state) => (id) => {
  const site = state.sites.find((n) => n.id === id);

  return !site.primary || state.sites.length === 1;
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

export const filteredSites = (state) => {
  return state.sites
    .filter(filterByStatus(state.statusFilter))
    .filter(filterBySearch(state.searchFilter));
};

export const countSitesForStatus = (state) => (status) => {
  return state.sites.filter(filterByStatus(status)).length;
};

export const siteHasVersionMismatch = (state) => (id) => {
  const site = state.sites.find((n) => n.id === id);
  const primarySite = state.sites.find((n) => n.primary);

  return site?.version !== primarySite?.version || site?.revision !== primarySite?.revision;
};
