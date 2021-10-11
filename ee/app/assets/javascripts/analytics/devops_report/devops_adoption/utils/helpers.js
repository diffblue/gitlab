/**
 * A helper function which accepts the enabledNamespaces,
 *
 * @param {Object} params the enabledNamespaces data, and the check for open modals
 *
 * @return {Boolean} a boolean to determine if table data should be polled
 */
export const shouldPollTableData = ({ enabledNamespaces, openModal }) => {
  if (openModal) {
    return false;
  } else if (!enabledNamespaces.length) {
    return true;
  }

  const anyPendingEnabledNamespaces = enabledNamespaces.some(
    (node) => node.latestSnapshot === null,
  );

  return anyPendingEnabledNamespaces;
};

/**
 * A helper function which extracts the total feature adoption count for a group
 * of snapshot data, filtered out by specific features / columns
 *
 * @param { Array } snapshots the snapshot data for a given group node
 * @param { Array } cols the columns which need to be used for the calculation
 *
 * @return { Array } an array containing the adopted counts for the given columns
 */
export const getAdoptedCountsByCols = (snapshots, cols) => {
  return snapshots.reduce((acc, snapshot) => {
    const adoptedCount = cols.reduce((adopted, col) => {
      return snapshot[col.key] ? adopted + 1 : adopted;
    }, 0);

    return [...acc, adoptedCount];
  }, []);
};
