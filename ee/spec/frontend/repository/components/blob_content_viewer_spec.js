import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BlobButtonGroup from '~/repository/components/blob_button_group.vue';
import BlobContentViewer from '~/repository/components/blob_content_viewer.vue';
import blobInfoQuery from '~/repository/queries/blob_info.query.graphql';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import {
  simpleViewerMock,
  projectMock,
  userPermissionsMock,
  propsMock,
  refMock,
} from 'jest/repository/mock_data';

jest.mock('~/lib/utils/common_utils');
Vue.use(VueRouter);
const router = new VueRouter();

let wrapper;
let mockResolver;

Vue.use(VueApollo);

const createComponent = async (mockData = {}) => {
  const {
    blob = simpleViewerMock,
    empty = projectMock.repository.empty,
    pushCode = userPermissionsMock.pushCode,
    forkProject = userPermissionsMock.forkProject,
    downloadCode = userPermissionsMock.downloadCode,
    createMergeRequestIn = userPermissionsMock.createMergeRequestIn,
    isBinary,
    inject = {},
    path = propsMock.projectPath,
  } = mockData;

  const project = {
    ...projectMock,
    userPermissions: {
      pushCode,
      forkProject,
      downloadCode,
      createMergeRequestIn,
    },
    repository: { empty, blobs: { nodes: [blob] } },
  };

  mockResolver = jest.fn().mockResolvedValue({
    data: { isBinary, project },
  });

  const fakeApollo = createMockApollo([[blobInfoQuery, mockResolver]]);

  wrapper = mountExtended(BlobContentViewer, {
    router,
    apolloProvider: fakeApollo,
    propsData: {
      ...propsMock,
      path,
    },
    mixins: [{ data: () => ({ ref: refMock }) }],
    provide: { ...inject },
  });

  await waitForPromises();
};

describe('Blob content viewer component', () => {
  const findBlobButtonGroup = () => wrapper.findComponent(BlobButtonGroup);

  beforeEach(() => {
    gon.features = { highlightJs: true };
    isLoggedIn.mockReturnValue(true);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('BlobHeader action slot', () => {
    describe('BlobButtonGroup', () => {
      const {
        repository: { empty },
      } = projectMock;

      afterEach(() => {
        delete gon.current_username;
      });

      it.each`
        canPushCode | canDownloadCode | username   | canLock
        ${true}     | ${true}         | ${'root'}  | ${true}
        ${false}    | ${true}         | ${'root'}  | ${false}
        ${true}     | ${false}        | ${'root'}  | ${false}
        ${true}     | ${true}         | ${'peter'} | ${false}
      `(
        'passes the correct lock states',
        async ({ canPushCode, canDownloadCode, username, canLock }) => {
          gon.current_username = username;

          await createComponent({
            pushCode: canPushCode,
            downloadCode: canDownloadCode,
            empty,
            path: 'locked_file.js',
          });

          expect(findBlobButtonGroup().props('canLock')).toBe(canLock);
        },
      );
    });
  });
});
