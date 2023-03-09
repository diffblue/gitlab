import { GlPagination, GlTable } from '@gitlab/ui';
import { mount } from '@vue/test-utils';

import { nextTick } from 'vue';
import AuditEventsTable from 'ee/audit_events/components/audit_events_table.vue';
import setWindowLocation from 'helpers/set_window_location_helper';
import createEvents from '../mock_data';

const EVENTS = createEvents();

describe('AuditEventsTable component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    return mount(AuditEventsTable, {
      propsData: {
        events: EVENTS,
        isLastPage: false,
        ...props,
      },
    });
  };

  const getCell = (trIdx, tdIdx) => {
    return wrapper
      .findComponent(GlTable)
      .find('tbody')
      .findAll('tr')
      .at(trIdx)
      .findAll('td')
      .at(tdIdx);
  };

  beforeEach(() => {
    setWindowLocation('https://localhost');

    wrapper = createComponent();
  });

  describe('Table behaviour', () => {
    it('should show', () => {
      expect(getCell(0, 1).text()).toBe('User');
    });

    it('should show the empty state if there is no data', async () => {
      wrapper.setProps({ events: [] });
      await nextTick();
      expect(getCell(0, 0).text()).toBe('There are no records to show');
    });
  });

  describe('Pagination behaviour', () => {
    it('should show', () => {
      expect(wrapper.findComponent(GlPagination).exists()).toBe(true);
    });

    it('should hide if there is no data', async () => {
      wrapper.setProps({ events: [] });
      await nextTick();
      expect(wrapper.findComponent(GlPagination).exists()).toBe(false);
    });

    it('should get the page number from the URL', () => {
      setWindowLocation('?page=2');
      wrapper = createComponent();

      expect(wrapper.findComponent(GlPagination).props().value).toBe(2);
    });

    it('should not have a prevPage if the page is 1', () => {
      setWindowLocation('?page=1');
      wrapper = createComponent();

      expect(wrapper.findComponent(GlPagination).props().prevPage).toBe(null);
    });

    it('should set the prevPage to 1 if the page is 2', () => {
      setWindowLocation('?page=2');
      wrapper = createComponent();

      expect(wrapper.findComponent(GlPagination).props().prevPage).toBe(1);
    });

    it('should not have a nextPage if isLastPage is true', async () => {
      wrapper.setProps({ isLastPage: true });
      await nextTick();
      expect(wrapper.findComponent(GlPagination).props().nextPage).toBe(null);
    });

    it('should set the nextPage to 2 if the page is 1', () => {
      setWindowLocation('?page=1');
      wrapper = createComponent();

      expect(wrapper.findComponent(GlPagination).props().nextPage).toBe(2);
    });

    it('should set the nextPage to 2 if the page is not set', () => {
      expect(wrapper.findComponent(GlPagination).props().nextPage).toBe(2);
    });
  });
});
