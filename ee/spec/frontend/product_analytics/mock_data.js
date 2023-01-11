export const createInstanceResponse = (errors = []) => ({
  data: {
    projectInitializeProductAnalytics: {
      project: {
        id: 'gid://gitlab/Project/2',
        fullPath: '',
      },
      errors,
    },
  },
});

export const getJitsuKeyResponse = (jitsuKey = null) => ({
  data: {
    project: {
      id: 'gid://gitlab/Project/2',
      jitsuKey,
    },
  },
});
