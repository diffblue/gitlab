import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';

import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';

import CatalogHeader from 'ee/ci/catalog/components/list/catalog_header.vue';
import ciResourcesPage from 'ee/ci/catalog/components/pages/ci_resources_page.vue';
import CiResourcesList from 'ee/ci/catalog/components/list/ci_resources_list.vue';
import EmptyState from 'ee/ci/catalog/components/list/empty_state.vue';
import getCiCatalogResources from 'ee/ci/catalog/graphql/queries/get_ci_catalog_resources.query.graphql';
import { cacheConfig } from 'ee/ci/catalog/graphql/settings';

import {
  generateEmptyCatalogResponse,
  generateCatalogResponse,
  generateCatalogResponsePage2,
} from '../../mock';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('CiResourcesPage', () => {
  let wrapper;
  let catalogResourcesResponse;

  const defaultProvide = { projectFullPath: 'my-org/project' };

  const createComponent = () => {
    const handlers = [[getCiCatalogResources, catalogResourcesResponse]];
    const mockApollo = createMockApollo(handlers, {}, cacheConfig);

    wrapper = shallowMountExtended(ciResourcesPage, {
      provide: {
        ...defaultProvide,
      },
      apolloProvider: mockApollo,
    });

    return waitForPromises();
  };

  const findCatalogHeader = () => wrapper.findComponent(CatalogHeader);
  const findCiResourcesList = () => wrapper.findComponent(CiResourcesList);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(EmptyState);

  beforeEach(() => {
    catalogResourcesResponse = jest.fn();
  });

  describe('when initial queries are loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a loading icon and no list', () => {
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findEmptyState().exists()).toBe(false);
      expect(findCiResourcesList().exists()).toBe(false);
    });
  });

  describe('when queries have loaded', () => {
    it('renders the Catalog Header', async () => {
      await createComponent();

      expect(findCatalogHeader().exists()).toBe(true);
    });

    describe('and there are no resources', () => {
      beforeEach(async () => {
        const emptyNodesRes = generateEmptyCatalogResponse();
        catalogResourcesResponse.mockResolvedValue(emptyNodesRes);

        await createComponent();
      });
      it('renders the empty state', () => {
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(true);
        expect(findCiResourcesList().exists()).toBe(false);
      });
    });

    describe('and there are resources', () => {
      const res = generateCatalogResponse();
      const { nodes, pageInfo, count } = res.data.ciCatalogResources;

      beforeEach(async () => {
        catalogResourcesResponse.mockResolvedValue(res);

        await createComponent();
      });
      it('renders the resources list', () => {
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(false);
        expect(findCiResourcesList().exists()).toBe(true);
      });

      it('passes down props to the resources list', () => {
        expect(findCiResourcesList().props()).toMatchObject({
          currentPage: 1,
          resources: nodes,
          pageInfo,
          totalCount: count,
        });
      });
    });
  });

  describe('pagination', () => {
    it.each`
      eventName       | generateResponse                | generateResponse2
      ${'onPrevPage'} | ${generateCatalogResponse}      | ${generateCatalogResponsePage2}
      ${'onNextPage'} | ${generateCatalogResponsePage2} | ${generateCatalogResponse}
    `(
      'refetch query with new params when receiving $eventName',
      async ({ eventName, generateResponse, generateResponse2 }) => {
        const response1 = generateResponse();

        const { pageInfo } = response1.data.ciCatalogResources;
        const response2 = generateResponse2();

        catalogResourcesResponse.mockResolvedValueOnce(response1);
        catalogResourcesResponse.mockResolvedValue(response2);

        await createComponent();

        expect(catalogResourcesResponse).toHaveBeenCalledTimes(1);

        await findCiResourcesList().vm.$emit(eventName);

        expect(catalogResourcesResponse).toHaveBeenCalledTimes(2);

        if (eventName === 'onNextPage') {
          expect(catalogResourcesResponse.mock.calls[1][0]).toEqual({
            after: pageInfo.endCursor,
            first: 20,
            fullPath: defaultProvide.projectFullPath,
          });
        } else {
          expect(catalogResourcesResponse.mock.calls[1][0]).toEqual({
            before: pageInfo.startCursor,
            last: 20,
            first: null,
            fullPath: defaultProvide.projectFullPath,
          });
        }
      },
    );
  });

  describe('pages count', () => {
    describe('when the fetchMore call suceeds', () => {
      beforeEach(async () => {
        const res = generateCatalogResponse();
        catalogResourcesResponse.mockResolvedValue(res);

        await createComponent();
      });

      it('increments and drecrements the page count correctly', async () => {
        expect(findCiResourcesList().props().currentPage).toBe(1);

        findCiResourcesList().vm.$emit('onNextPage');
        await waitForPromises();

        expect(findCiResourcesList().props().currentPage).toBe(2);

        await findCiResourcesList().vm.$emit('onPrevPage');
        await waitForPromises();

        expect(findCiResourcesList().props().currentPage).toBe(1);
      });
    });

    describe('when the fetchMore call fails', () => {
      const errorMessage = 'there was an error';

      describe('for next page', () => {
        beforeEach(async () => {
          const res = generateCatalogResponse();
          catalogResourcesResponse.mockResolvedValueOnce(res);
          catalogResourcesResponse.mockRejectedValue({ message: errorMessage });

          await createComponent();
        });

        it('does not increment the page and calls createAlert', async () => {
          expect(findCiResourcesList().props().currentPage).toBe(1);

          findCiResourcesList().vm.$emit('onNextPage');
          await waitForPromises();

          expect(findCiResourcesList().props().currentPage).toBe(1);
          expect(createAlert).toHaveBeenCalledWith({ message: errorMessage, variant: 'danger' });
        });
      });

      describe('for previous page', () => {
        beforeEach(async () => {
          const res = generateCatalogResponse();
          // Initial query
          catalogResourcesResponse.mockResolvedValueOnce(res);
          // When clicking on next
          catalogResourcesResponse.mockResolvedValueOnce(res);
          // when clicking on previous
          catalogResourcesResponse.mockRejectedValue({ message: errorMessage });

          await createComponent();
        });

        it('does not increment the page and calls createAlert', async () => {
          expect(findCiResourcesList().props().currentPage).toBe(1);

          findCiResourcesList().vm.$emit('onNextPage');
          await waitForPromises();

          expect(findCiResourcesList().props().currentPage).toBe(2);

          findCiResourcesList().vm.$emit('onPreviousPage');
          await waitForPromises();

          expect(findCiResourcesList().props().currentPage).toBe(2);
          expect(createAlert).toHaveBeenCalledWith({ message: errorMessage, variant: 'danger' });
        });
      });
    });
  });
});
