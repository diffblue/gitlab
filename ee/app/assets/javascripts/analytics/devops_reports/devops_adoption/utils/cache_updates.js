import produce from 'immer';
import devopsAdoptionEnabledNamespacesQuery from '../graphql/queries/devops_adoption_enabled_namespaces.query.graphql';

export const addEnabledNamespacesToCache = (store, enabledNamespaces, variables) => {
  const sourceData = store.readQuery({
    query: devopsAdoptionEnabledNamespacesQuery,
    variables,
  });

  const data = produce(sourceData, (draftData) => {
    draftData.devopsAdoptionEnabledNamespaces.nodes = [
      ...draftData.devopsAdoptionEnabledNamespaces.nodes,
      ...enabledNamespaces,
    ];
  });

  store.writeQuery({
    query: devopsAdoptionEnabledNamespacesQuery,
    variables,
    data,
  });
};

export const deleteEnabledNamespacesFromCache = (store, enabledNamespaceIds, variables) => {
  const sourceData = store.readQuery({
    query: devopsAdoptionEnabledNamespacesQuery,
    variables,
  });

  const updatedData = produce(sourceData, (draftData) => {
    draftData.devopsAdoptionEnabledNamespaces.nodes = draftData.devopsAdoptionEnabledNamespaces.nodes.filter(
      ({ id }) => !enabledNamespaceIds.includes(id),
    );
  });

  store.writeQuery({
    query: devopsAdoptionEnabledNamespacesQuery,
    variables,
    data: updatedData,
  });
};
