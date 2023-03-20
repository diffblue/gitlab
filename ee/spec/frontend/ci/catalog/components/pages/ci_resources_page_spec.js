import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';

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
      const { nodes, pageInfo } = res.data.ciCatalogResources;

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
        expect(findCiResourcesList().props()).toEqual(
          expect.objectContaining({
            resources: nodes,
            pageInfo,
          }),
        );
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
});
