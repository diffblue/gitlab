import produce from 'immer';
import userWorkspacesQuery from '../graphql/queries/user_workspaces_list.query.graphql';

export const addWorkspace = (store, workspace) => {
  const initialData = {
    currentUser: {
      workspaces: {
        nodes: [],
      },
    },
  };

  store.updateQuery({ query: userWorkspacesQuery }, (sourceData) =>
    produce(sourceData, (draftData) => {
      (draftData || initialData).currentUser.workspaces.nodes.unshift(workspace);
    }),
  );
};
