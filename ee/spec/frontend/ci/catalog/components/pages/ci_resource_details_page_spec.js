import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { cacheConfig } from 'ee/ci/catalog/graphql/settings';
import getCatalogCiResourceDetails from 'ee/ci/catalog/graphql/queries/get_ci_catalog_resource_details.query.graphql';
import CiResourceAbout from 'ee/ci/catalog/components/details/ci_resource_about.vue';
import CiResourceDetails from 'ee/ci/catalog/components/details/ci_resource_details.vue';
import CiResourceDetailsPage from 'ee/ci/catalog/components/pages/ci_resource_details_page.vue';
import CiResourceHeader from 'ee/ci/catalog/components/details/ci_resource_header.vue';
import { createRouter } from 'ee/ci/catalog/router/index';
import { CI_RESOURCE_DETAILS_PAGE_NAME } from 'ee/ci/catalog/router/constants';
import { catalogDetailsMock } from '../../mock';

Vue.use(VueApollo);
Vue.use(VueRouter);

let router;

const defaultDetailsValues = { ...catalogDetailsMock.data.ciCatalogResource };

describe('CiResourceDetailsPage', () => {
  let wrapper;
  let detailsResponse;

  const defaultProps = {};

  const findAboutComponent = () => wrapper.findComponent(CiResourceAbout);
  const findDetailsComponent = () => wrapper.findComponent(CiResourceDetails);
  const findHeaderComponent = () => wrapper.findComponent(CiResourceHeader);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createComponent = ({ props = {} } = {}) => {
    const handlers = [[getCatalogCiResourceDetails, detailsResponse]];

    const mockApollo = createMockApollo(handlers, undefined, cacheConfig);

    wrapper = shallowMount(CiResourceDetailsPage, {
      router,
      apolloProvider: mockApollo,
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
    detailsResponse = jest.fn();

    router = createRouter();
    await router.push({
      name: CI_RESOURCE_DETAILS_PAGE_NAME,
      params: { id: defaultDetailsValues.id },
    });

    detailsResponse.mockResolvedValue(catalogDetailsMock);
    createComponent();
  });

  describe('when loading', () => {
    it('renders a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when data has loaded', () => {
    beforeEach(async () => {
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
          description: defaultDetailsValues.description,
          icon: defaultDetailsValues.icon,
          name: defaultDetailsValues.name,
          resourceId: defaultDetailsValues.id,
          rootNamespace: defaultDetailsValues.rootNamespace,
          webPath: defaultDetailsValues.webPath,
        });
      });
    });

    describe('Catalog about', () => {
      it('exists', () => {
        expect(findAboutComponent().exists()).toBe(true);
      });

      it('passes expected props', () => {
        expect(findAboutComponent().props()).toEqual({
          openIssuesCount: defaultDetailsValues.openIssuesCount,
          openMergeRequestsCount: defaultDetailsValues.openMergeRequestsCount,
          versions: defaultDetailsValues.versions.nodes,
          webPath: defaultDetailsValues.webPath,
        });
      });
    });

    describe('Catalog details', () => {
      it('exists', () => {
        expect(findDetailsComponent().exists()).toBe(true);
      });

      it('passes expected props', () => {
        expect(findDetailsComponent().props()).toEqual({
          readmeHtml: defaultDetailsValues.readmeHtml,
        });
      });
    });
  });
});
