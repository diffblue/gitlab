import { GlKeysetPagination } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import CiResourcesList from 'ee/ci/catalog/components/list/ci_resources_list.vue';
import CiResourcesListItem from 'ee/ci/catalog/components/list/ci_resources_list_item.vue';
import { ciCatalogResourcesItemsCount } from 'ee/ci/catalog/graphql/settings';
import {
  generateCatalogResponseWithOnlyOnePage,
  generateCatalogResponse,
  generateCatalogResponsePage2,
  generateCatalogResponseLastPage,
} from '../../mock';

describe('CiResourcesList', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    const { nodes, pageInfo, count } = generateCatalogResponse().data.ciCatalogResources;

    const defaultProps = {
      currentPage: 1,
      resources: nodes,
      pageInfo,
      totalCount: count,
    };

    wrapper = shallowMountExtended(CiResourcesList, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlKeysetPagination,
      },
    });
  };

  const findPageCount = () => wrapper.findByTestId('pageCount');
  const findResourcesListItems = () => wrapper.findAllComponents(CiResourcesListItem);
  const findPrevBtn = () => wrapper.findByTestId('prevButton');
  const findNextBtn = () => wrapper.findByTestId('nextButton');

  describe.each`
    generateResponse                          | previousPageState | nextPageState | pageText    | expectedTotal                   | currentPage
    ${generateCatalogResponseWithOnlyOnePage} | ${'disabled'}     | ${'disabled'} | ${'1 of 1'} | ${5}                            | ${1}
    ${generateCatalogResponse}                | ${'disabled'}     | ${'enabled'}  | ${'1 of 2'} | ${ciCatalogResourcesItemsCount} | ${1}
    ${generateCatalogResponsePage2}           | ${'enabled'}      | ${'enabled'}  | ${'2 of 4'} | ${ciCatalogResourcesItemsCount} | ${2}
    ${generateCatalogResponseLastPage}        | ${'enabled'}      | ${'disabled'} | ${'2 of 2'} | ${ciCatalogResourcesItemsCount} | ${2}
  `(
    'when on page $pageText',
    ({
      currentPage,
      expectedTotal,
      pageText,
      previousPageState,
      nextPageState,
      generateResponse,
    }) => {
      const response = generateResponse();
      const { nodes, pageInfo, count } = response.data.ciCatalogResources;

      beforeEach(async () => {
        await createComponent({
          props: { currentPage, resources: nodes, pageInfo, totalCount: count },
        });
      });

      it('shows the right number of items', () => {
        expect(findResourcesListItems()).toHaveLength(expectedTotal);
      });

      it(`shows the keyset control for previous page as ${previousPageState}`, () => {
        const disableAttr = findPrevBtn().attributes('disabled');

        if (previousPageState === 'disabled') {
          expect(disableAttr).toBeDefined();
        } else {
          expect(disableAttr).toBeUndefined();
        }
      });

      it(`shows the keyset control for next page as ${nextPageState}`, () => {
        const disableAttr = findNextBtn().attributes('disabled');

        if (nextPageState === 'disabled') {
          expect(disableAttr).toBeDefined();
        } else {
          expect(disableAttr).toBeUndefined();
        }
      });

      it('shows the correct count of current page', () => {
        expect(findPageCount().text()).toContain(pageText);
      });
    },
  );

  describe('when there is an error getting the page count', () => {
    beforeEach(() => {
      createComponent({ props: { totalCount: null } });
    });

    it('hides the page count', () => {
      expect(findPageCount().exists()).toBe(false);
    });
  });

  describe('emitted events', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      btnText       | elFinder       | eventName
      ${'previous'} | ${findPrevBtn} | ${'onPrevPage'}
      ${'next'}     | ${findNextBtn} | ${'onNextPage'}
    `('emits $eventName when clicking on the $btnText button', async ({ elFinder, eventName }) => {
      await elFinder().vm.$emit('click');

      expect(wrapper.emitted(eventName)).toHaveLength(1);
    });
  });
});
