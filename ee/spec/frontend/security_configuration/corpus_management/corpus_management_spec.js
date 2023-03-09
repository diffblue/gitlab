import { merge } from 'lodash';
import { GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';

import CorpusManagement from 'ee/security_configuration/corpus_management/components/corpus_management.vue';
import CorpusTable from 'ee/security_configuration/corpus_management/components/corpus_table.vue';
import CorpusUpload from 'ee/security_configuration/corpus_management/components/corpus_upload.vue';
import EmptyState from 'ee/security_configuration/corpus_management/components/empty_state.vue';
import getCorpusesQuery from 'ee/security_configuration/corpus_management/graphql/queries/get_corpuses.query.graphql';
import deleteCorpusMutation from 'ee/security_configuration/corpus_management/graphql/mutations/delete_corpus.mutation.graphql';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import {
  getCorpusesQueryResponse,
  deleteCorpusMutationResponse,
  getCorpusesBigListQueryResponse,
} from './mock_data';

const TEST_PROJECT_FULL_PATH = '/namespace/project';
const TEST_CORPUS_HELP_PATH = '/docs/corpus-management';
const TEST_EMPTY_STATE_SVG_PATH = '/illustrations/no_commits.svg';

describe('EE - CorpusManagement', () => {
  let wrapper;

  const createMockApolloProvider = ({
    getCorpusesQueryRequestHandler = jest.fn().mockResolvedValue(getCorpusesQueryResponse),
    deleteCorpusMutationHandler = jest.fn().mockResolvedValue(deleteCorpusMutationResponse),
  } = {}) => {
    Vue.use(VueApollo);

    const requestHandlers = [
      [getCorpusesQuery, getCorpusesQueryRequestHandler],
      [deleteCorpusMutation, deleteCorpusMutationHandler],
    ];

    const mockResolvers = {
      Query: {
        uploadState() {
          return {
            isUploading: false,
            progress: 0,
            cancelSource: null,
            uploadedPackageId: null,
            errors: {
              name: '',
              file: '',
              __typename: 'Errors',
            },
            __typename: 'UploadState',
          };
        },
      },
    };

    return createMockApollo(requestHandlers, mockResolvers);
  };

  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findCorpusTable = () => wrapper.findComponent(CorpusTable);
  const findEmptyState = () => wrapper.findComponent(EmptyState);
  const findCorpusUpload = () => wrapper.findComponent(CorpusUpload);
  const findCorpusManagement = () => wrapper.findComponent(CorpusManagement);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const nextPage = async (cursor) => {
    findPagination().vm.$emit('next', cursor);
    await nextTick();
  };

  const prevPage = async (cursor) => {
    findPagination().vm.$emit('prev', cursor);
    await nextTick();
  };

  const createComponentFactory = (mountFn = shallowMount) => (options = {}) => {
    wrapper = mountFn(CorpusManagement, {
      provide: {
        projectFullPath: TEST_PROJECT_FULL_PATH,
        corpusHelpPath: TEST_CORPUS_HELP_PATH,
        emptyStateSvgPath: TEST_EMPTY_STATE_SVG_PATH,
      },
      apolloProvider: createMockApolloProvider(),
      ...options,
    });
  };

  const createComponent = createComponentFactory();

  describe('corpus management', () => {
    describe('when loaded', () => {
      it('bootstraps and renders the component', async () => {
        createComponent();
        await waitForPromises();

        expect(findCorpusManagement().exists()).toBe(true);
        expect(findCorpusTable().exists()).toBe(true);
        expect(findCorpusUpload().exists()).toBe(true);
        expect(findLoadingIcon().exists()).toBe(false);
      });

      it('renders the correct header', async () => {
        createComponent();
        await waitForPromises();

        const header = findCorpusManagement().find('header');
        expect(header.element).toMatchSnapshot();
      });

      describe('pagination', () => {
        it('hides pagination when no previous or next pages are available', async () => {
          createComponent({
            apolloProvider: createMockApolloProvider({
              getCorpusesQueryRequestHandler: jest.fn().mockResolvedValue(
                merge({}, getCorpusesQueryResponse, {
                  data: {
                    project: {
                      corpuses: {
                        pageInfo: {
                          hasNextPage: false,
                          hasPreviousPage: false,
                        },
                      },
                    },
                  },
                }),
              ),
            }),
          });
          await waitForPromises();

          expect(findPagination().exists()).toBe(false);
        });

        it('passes correct props to GlKeysetPagination', async () => {
          createComponent();
          await waitForPromises();

          expect(findPagination().exists()).toBe(true);
          expect(findPagination().props()).toMatchObject({
            disabled: false,
            endCursor: 'end-cursor',
            hasNextPage: true,
            hasPreviousPage: true,
            nextButtonLink: null,
            nextText: 'Next',
            prevButtonLink: null,
            prevText: 'Prev',
            startCursor: 'start-cursor',
          });
        });

        it('updates query variables when going to previous page', async () => {
          const getCorpusesQueryRequestHandler = jest
            .fn()
            .mockResolvedValue(getCorpusesQueryResponse);

          createComponent({
            apolloProvider: createMockApolloProvider({ getCorpusesQueryRequestHandler }),
          });
          await waitForPromises();

          await prevPage(getCorpusesQueryResponse.data.project.corpuses.pageInfo.startCursor);

          expect(getCorpusesQueryRequestHandler).toHaveBeenCalledWith({
            beforeCursor: getCorpusesQueryResponse.data.project.corpuses.pageInfo.startCursor,
            afterCursor: '',
            projectPath: TEST_PROJECT_FULL_PATH,
            lastPageSize: 10,
            firstPageSize: null,
          });
        });

        it('updates query variables when going to next page', async () => {
          const getCorpusesQueryRequestHandler = jest
            .fn()
            .mockResolvedValue(getCorpusesQueryResponse);

          createComponent({
            apolloProvider: createMockApolloProvider({ getCorpusesQueryRequestHandler }),
          });
          await waitForPromises();

          await nextPage(getCorpusesQueryResponse.data.project.corpuses.pageInfo.endCursor);

          expect(getCorpusesQueryRequestHandler).toHaveBeenLastCalledWith({
            afterCursor: getCorpusesQueryResponse.data.project.corpuses.pageInfo.endCursor,
            beforeCursor: '',
            projectPath: TEST_PROJECT_FULL_PATH,
            firstPageSize: 10,
            lastPageSize: null,
          });
        });
      });

      describe('corpus deletion', () => {
        const deleteCorpusMutationHandler = jest
          .fn()
          .mockResolvedValue(deleteCorpusMutationResponse);

        it('deletes the corpus', async () => {
          const mutationVars = { input: { id: 1 } };

          const getCorpusesQueryRequestHandler = jest
            .fn()
            .mockResolvedValue(getCorpusesQueryResponse);

          createComponent({
            apolloProvider: createMockApolloProvider({
              getCorpusesQueryRequestHandler,
              deleteCorpusMutationHandler,
            }),
          });
          await waitForPromises();

          expect(getCorpusesQueryRequestHandler).toHaveBeenCalledTimes(1);

          const corpusTable = findCorpusTable();
          corpusTable.vm.$emit('delete', mutationVars.input.id);
          await waitForPromises();

          expect(deleteCorpusMutationHandler).toHaveBeenCalledWith(mutationVars);

          expect(getCorpusesQueryRequestHandler).toHaveBeenCalledTimes(2);
          expect(getCorpusesQueryRequestHandler).toHaveBeenNthCalledWith(2, {
            afterCursor: '',
            beforeCursor: '',
            firstPageSize: 10,
            lastPageSize: null,
            projectPath: '/namespace/project',
          });
        });

        it('deletes last item on page and returns to previous page', async () => {
          const getCorpusesQueryRequestHandler = jest
            .fn()
            .mockResolvedValue(getCorpusesBigListQueryResponse);

          createComponent({
            apolloProvider: createMockApolloProvider({
              getCorpusesQueryRequestHandler,
              deleteCorpusMutationHandler,
            }),
          });

          await waitForPromises();
          await nextPage();
          await waitForPromises();

          const lastItemInListId =
            getCorpusesBigListQueryResponse.data.project.corpuses.nodes[10].id;

          findCorpusTable().vm.$emit('delete', lastItemInListId);

          await waitForPromises();

          expect(getCorpusesQueryRequestHandler).toHaveBeenCalledTimes(3);
          expect(deleteCorpusMutationHandler).toHaveBeenCalledWith({
            input: { id: lastItemInListId },
          });
          expect(findCorpusTable().exists()).toBe(true);
          expect(findEmptyState().exists()).toBe(false);
        });
      });
    });

    describe('when loading', () => {
      it('shows loading state when loading', () => {
        createComponent();

        expect(findCorpusManagement().exists()).toBe(true);
        expect(findCorpusUpload().exists()).toBe(false);
        expect(findLoadingIcon().exists()).toBe(true);
        expect(findCorpusTable().exists()).toBe(false);
      });
    });

    describe('empty state', () => {
      it('should render empty state if no corpuses exist', async () => {
        createComponent({
          apolloProvider: createMockApolloProvider({
            getCorpusesQueryRequestHandler: jest.fn().mockResolvedValue({
              data: {
                project: {
                  corpuses: {
                    nodes: [],
                  },
                },
              },
            }),
          }),
        });
        await waitForPromises();
        expect(findEmptyState().exists()).toBe(true);
      });
    });
  });
});
