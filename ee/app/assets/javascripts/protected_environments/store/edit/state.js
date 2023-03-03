export const state = ({ projectId }) => ({
  projectId,
  loading: false,
  protectedEnvironments: [],
  usersForRules: {},
  newDeployAccessLevelsForEnvironment: {},
  editingRules: {},
});
