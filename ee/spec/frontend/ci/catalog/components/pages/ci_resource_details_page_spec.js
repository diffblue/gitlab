import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { cacheConfig } from 'ee/ci/catalog/graphql/settings';

import getCiCatalogResourceSharedData from 'ee/ci/catalog/graphql/queries/get_ci_catalog_resource_shared_data.query.graphql';
import getCiCatalogResourceDetails from 'ee/ci/catalog/graphql/queries/get_ci_catalog_resource_details.query.graphql';

import CiResourceAbout from 'ee/ci/catalog/components/details/ci_resource_about.vue';
import CiResourceDetails from 'ee/ci/catalog/components/details/ci_resource_details.vue';
import CiResourceDetailsPage from 'ee/ci/catalog/components/pages/ci_resource_details_page.vue';
import CiResourceHeader from 'ee/ci/catalog/components/details/ci_resource_header.vue';
import CiResourceHeaderSkeletonLoader from 'ee/ci/catalog/components/details/ci_resource_header_skeleton_loader.vue';

import { createRouter } from 'ee/ci/catalog/router/index';
import { CI_RESOURCE_DETAILS_PAGE_NAME } from 'ee/ci/catalog/router/constants';
import { catalogSharedDataMock, catalogAdditionalDetailsMock } from '../../mock';

Vue.use(VueApollo);
Vue.use(VueRouter);

let router;

const defaultSharedData = { ...catalogSharedDataMock.data.ciCatalogResource };
const defaultAdditionalData = { ...catalogAdditionalDetailsMock.data.ciCatalogResource };

describe('CiResourceDetailsPage', () => {
  let wrapper;
  let sharedDataResponse;
  let additionalDataResponse;

  const defaultProps = {};

  const defaultProvide = {
    ciCatalogPath: '/ci/catalog/resources',
  };

  const findAboutComponent = () => wrapper.findComponent(CiResourceAbout);
  const findDetailsComponent = () => wrapper.findComponent(CiResourceDetails);
  const findHeaderComponent = () => wrapper.findComponent(CiResourceHeader);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findHeaderSkeletonLoader = () => wrapper.findComponent(CiResourceHeaderSkeletonLoader);

  const createComponent = ({ props = {} } = {}) => {
    const handlers = [
      [getCiCatalogResourceSharedData, sharedDataResponse],
      [getCiCatalogResourceDetails, additionalDataResponse],
    ];

    const mockApollo = createMockApollo(handlers, undefined, cacheConfig);

    wrapper = shallowMount(CiResourceDetailsPage, {
      router,
      apolloProvider: mockApollo,
      provide: {
        ...defaultProvide,
      },
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        RouterView: true,
      },
    });
  };

  beforeEach(async () => {
    sharedDataResponse = jest.fn();
    additionalDataResponse = jest.fn();

    router = createRouter();
    await router.push({
      name: CI_RESOURCE_DETAILS_PAGE_NAME,
      params: { id: defaultSharedData.id },
    });
  });

  describe('when the app is loading', () => {
    describe('and shared data is pre-fetched', () => {
      beforeEach(() => {
        // By mocking a return value and not a promise, we skip the loading
        // to simulate having the pre-fetched query
        sharedDataResponse.mockReturnValueOnce(catalogSharedDataMock);
        additionalDataResponse.mockResolvedValue(catalogAdditionalDetailsMock);
        createComponent();
      });

      it('renders only the details loading state', () => {
        expect(findLoadingIcon().exists()).toBe(true);
        expect(findHeaderSkeletonLoader().exists()).toBe(false);
      });

      it('passes down the loading state to the about component', () => {
        sharedDataResponse.mockReturnValueOnce(catalogSharedDataMock);

        expect(findAboutComponent().props()).toMatchObject({
          isLoadingDetails: true,
          isLoadingSharedData: false,
        });
      });
    });

    describe('and shared data is not pre-fetched', () => {
      beforeEach(() => {
        sharedDataResponse.mockResolvedValue(catalogSharedDataMock);
        additionalDataResponse.mockResolvedValue(catalogAdditionalDetailsMock);
        createComponent();
      });

      it('renders all loading states', () => {
        expect(findLoadingIcon().exists()).toBe(true);
        expect(findHeaderSkeletonLoader().exists()).toBe(true);
      });

      it('passes down the loading state to the about component', () => {
        expect(findAboutComponent().props()).toMatchObject({
          isLoadingDetails: true,
          isLoadingSharedData: true,
        });
      });
    });
  });

  describe('and there are no resources', () => {
    beforeEach(async () => {
      const mockError = new Error('error');
      sharedDataResponse.mockRejectedValue(mockError);
      additionalDataResponse.mockRejectedValue(mockError);

      createComponent();
      await waitForPromises();
    });

    it('renders the empty state', () => {
      expect(findDetailsComponent().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().props('primaryButtonLink')).toBe(defaultProvide.ciCatalogPath);
    });
  });

  describe('when data has loaded', () => {
    beforeEach(async () => {
      sharedDataResponse.mockResolvedValue(catalogSharedDataMock);
      additionalDataResponse.mockResolvedValue(catalogAdditionalDetailsMock);
      createComponent();

      await waitForPromises();
    });

    it('does not render a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    describe('Catalog header', () => {
      it('exists', () => {
        expect(findHeaderComponent().exists()).toBe(true);
      });

      it('passes expected props', () => {
        expect(findHeaderComponent().props()).toEqual({
          description: defaultSharedData.description,
          icon: defaultSharedData.icon,
          latestVersion: defaultSharedData.latestVersion,
          name: defaultSharedData.name,
          pipelineStatus:
            defaultAdditionalData.versions.nodes[0].commit.pipelines.nodes[0].detailedStatus,
          resourceId: defaultSharedData.id,
          rootNamespace: defaultSharedData.rootNamespace,
          webPath: defaultSharedData.webPath,
        });
      });
    });

    describe('Catalog about', () => {
      it('exists', () => {
        expect(findAboutComponent().exists()).toBe(true);
      });

      it('passes expected props', () => {
        expect(findAboutComponent().props()).toEqual({
          isLoadingDetails: false,
          isLoadingSharedData: false,
          openIssuesCount: defaultAdditionalData.openIssuesCount,
          openMergeRequestsCount: defaultAdditionalData.openMergeRequestsCount,
          latestVersion: defaultSharedData.latestVersion,
          webPath: defaultSharedData.webPath,
        });
      });
    });

    describe('Catalog details', () => {
      it('exists', () => {
        expect(findDetailsComponent().exists()).toBe(true);
      });

      it('passes expected props', () => {
        expect(findDetailsComponent().props()).toEqual({
          readmeHtml: defaultAdditionalData.readmeHtml,
        });
      });
    });
  });
});
