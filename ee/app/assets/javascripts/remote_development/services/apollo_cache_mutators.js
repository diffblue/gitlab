import produce from 'immer';
import userWorkspacesQuery from '../graphql/queries/user_workspaces_list.query.graphql';

export const addWorkspace = (store, workspace) => {
  store.updateQuery({ query: userWorkspacesQuery }, (sourceData) =>
    produce(sourceData, (draftData) => {
      // If there's nothing in the query we don't really need to update it. It should just refetch naturally.
      if (!draftData) {
        return;
      }

      draftData.currentUser.workspaces.nodes.unshift(workspace);
    }),
  );
};
