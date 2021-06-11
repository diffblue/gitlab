import { GlPagination } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Pagination from 'ee/compliance_dashboard/components/shared/pagination.vue';
import setWindowLocation from 'helpers/set_window_location_helper';

describe('Pagination component', () => {
  let wrapper;
  const origin = 'https://localhost';

  const findGlPagination = () => wrapper.find(GlPagination);
  const getLink = (query) => wrapper.find(query).element.getAttribute('href');
  const findPrevPageLink = () => getLink('a.prev-page-item');
  const findNextPageLink = () => getLink('a.next-page-item');

  const createComponent = (isLastPage = false) => {
    return shallowMount(Pagination, {
      propsData: {
        isLastPage,
      },
      stubs: {
        GlPagination,
      },
    });
  };

  beforeEach(() => {
    setWindowLocation(origin);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when initialized', () => {
    beforeEach(() => {
      setWindowLocation('?page=2');
      wrapper = createComponent();
    });

    it('should get the page number from the URL', () => {
      expect(findGlPagination().props().value).toBe(2);
    });

    it('should create a link to the previous page', () => {
      expect(findPrevPageLink()).toBe(`${origin}/?page=1`);
    });

    it('should create a link to the next page', () => {
      expect(findNextPageLink()).toBe(`${origin}/?page=3`);
    });
  });

  describe('when on last page', () => {
    beforeEach(() => {
      setWindowLocation('?page=2');
      wrapper = createComponent(true);
    });

    it('should not have a nextPage if on the last page', () => {
      expect(findGlPagination().props().nextPage).toBe(null);
    });
  });

  describe('when there is only one page', () => {
    beforeEach(() => {
      setWindowLocation('?page=1');
      wrapper = createComponent(true);
    });

    it('should not display if there is only one page of results', () => {
      expect(findGlPagination().exists()).toEqual(false);
    });
  });
});
