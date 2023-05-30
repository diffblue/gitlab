export const state = ({ projectId }) => ({
  projectId,
  loading: false,
  protectedEnvironments: [],
  pageInfo: {},
  usersForRules: {},
  newDeployAccessLevelsForEnvironment: {},
  editingRules: {},
});
