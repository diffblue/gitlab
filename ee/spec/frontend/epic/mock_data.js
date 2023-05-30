import metaFixture from 'test_fixtures/epic/mock_meta.json';
import mockDataFixture from 'test_fixtures/epic/mock_data.json';
import { TEST_HOST } from 'spec/test_constants';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

const meta = JSON.parse(metaFixture.meta);
const initial = JSON.parse(metaFixture.initial);

export const mockEpicMeta = {
  ...convertObjectPropsToCamelCase(meta, {
    deep: true,
  }),
  allowSubEpics: true,
};

export const mockEpicData = convertObjectPropsToCamelCase(
  {
    ...mockDataFixture,
    ...initial,
    endpoint: TEST_HOST,
    sidebarCollapsed: false,
  },
  { deep: true },
);

export const mockEpicReferenceData = {
  data: {
    workspace: {
      id: 'gid://gitlab/Group/35',
      issuable: {
        id: 'gid://gitlab/Epic/36',
        reference: 'twitter&6',
        __typename: 'Epic',
      },
      __typename: 'Group',
    },
  },
};
