import { TEST_HOST } from 'spec/test_constants';

export const TEST_JITSU_KEY = 'gid://gitlab/Project/2';

export const TEST_JITSU_HOST = TEST_HOST;

export const TEST_JITSU_PROJECT_ID = 'gitlab-org/gitlab';

export const TEST_PROJECT_FULL_PATH = 'group-1/project-1';

export const TEST_PROJECT_ID = '2';

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
