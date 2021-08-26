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
