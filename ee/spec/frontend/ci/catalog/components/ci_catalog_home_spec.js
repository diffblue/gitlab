import { shallowMount } from '@vue/test-utils';
import { createRouter } from 'ee/ci/catalog/router';
import ciResourceDetailsPage from 'ee/ci/catalog/components/pages/ci_resource_details_page.vue';
import ciResourcesPage from 'ee/ci/catalog/components/pages/ci_resources_page.vue';
import CiCatalogHome from 'ee/ci/catalog/components/ci_catalog_home.vue';

describe('CiCatalogHome', () => {
  const defaultProps = {};
  const baseRoute = '/';
  const router = createRouter(baseRoute);

  const createComponent = ({ props = {} } = {}) => {
    shallowMount(CiCatalogHome, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      router,
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('router', () => {
      it.each`
        path         | component
        ${baseRoute} | ${ciResourcesPage}
        ${'/1'}      | ${ciResourceDetailsPage}
      `('when route is $path it renders the right component', async ({ path, component }) => {
        if (path !== '/') {
          await router.push(path);
        }

        const [root] = router.currentRoute.matched;

        expect(root.components.default).toBe(component);
      });
    });
  });
});
