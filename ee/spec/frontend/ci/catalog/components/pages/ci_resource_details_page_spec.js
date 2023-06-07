import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import { cacheConfig, catalogDetailsMock } from 'ee/ci/catalog/graphql/settings';
import getCatalogCiResourceDetails from 'ee/ci/catalog/graphql/queries/get_ci_catalog_resource_details.query.graphql';
import CiResourceAbout from 'ee/ci/catalog/components/details/ci_resource_about.vue';
import CiResourceDetails from 'ee/ci/catalog/components/details/ci_resource_details.vue';
import CiResourceDetailsPage from 'ee/ci/catalog/components/pages/ci_resource_details_page.vue';
import CiResourceHeader from 'ee/ci/catalog/components/details/ci_resource_header.vue';

Vue.use(VueApollo);

describe('CiResourceDetailsPage', () => {
  let wrapper;

  const defaultProps = {};

  const findAbout = () => wrapper.findComponent(CiResourceAbout);
  const findDetails = () => wrapper.findComponent(CiResourceDetails);
  const findHeader = () => wrapper.findComponent(CiResourceHeader);

  const createComponent = ({ props = {} } = {}) => {
    const mockApollo = createMockApollo(undefined, undefined, cacheConfig);

    // TODO: remove this when the query is no longer client side
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getCatalogCiResourceDetails,
      data: {
        ciCatalogResourcesDetails: {
          nodes: [catalogDetailsMock],
        },
      },
    });

    wrapper = shallowMount(CiResourceDetailsPage, {
      apolloProvider: mockApollo,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('Catalog header', () => {
      it('exists', () => {
        expect(findHeader().exists()).toBe(true);
      });

      it('passes expected props', () => {
        expect(findHeader().props()).toEqual({
          description: catalogDetailsMock.description,
          name: catalogDetailsMock.name,
          rootNamespace: catalogDetailsMock.rootNamespace,
        });
      });
    });

    describe('Catalog about', () => {
      it('exists', () => {
        expect(findAbout().exists()).toBe(true);
      });

      it('passes expected props', () => {
        expect(findAbout().props()).toEqual({
          statistics: catalogDetailsMock.statistics,
          versions: catalogDetailsMock.versions.nodes,
        });
      });
    });

    describe('Catalog details', () => {
      it('exists', () => {
        expect(findDetails().exists()).toBe(true);
      });

      it('passes expected props', () => {
        expect(findDetails().props()).toEqual({
          readmeHtml: catalogDetailsMock.readmeHtml,
        });
      });
    });
  });
});
