import { GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import AlertFilters from 'ee/threat_monitoring/components/alerts/alert_filters.vue';
import { ALL, DEFAULT_FILTERS, STATUSES } from 'ee/threat_monitoring/components/alerts/constants';
import { trimText } from 'helpers/text_helper';

describe('AlertFilters component', () => {
  let wrapper;

  const findDropdownItemAtIndex = (index) => wrapper.findAllComponents(GlDropdownItem).at(index);
  const clickDropdownItemAtIndex = (index) => findDropdownItemAtIndex(index).vm.$emit('click');
  const findSearch = () => wrapper.findComponent(GlSearchBoxByType);
  const findDropdownMessage = () =>
    wrapper.find('[data-testid="policy-alert-status-filter"] .dropdown button').text();

  const createWrapper = ({ filters = DEFAULT_FILTERS, method = shallowMount } = {}) => {
    wrapper = method(AlertFilters, { propsData: { filters } });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('Policy Name Filter', () => {
    beforeEach(() => {
      createWrapper({});
    });

    describe('default state', () => {
      it('shows policy name search box', () => {
        const search = findSearch();
        expect(search.exists()).toBe(true);
        expect(search.attributes('value')).toBe('');
      });

      it('does emit an event with a user-defined string', async () => {
        const searchTerm = 'abc';
        const search = findSearch();
        search.vm.$emit('input', searchTerm);
        await wrapper.vm.$nextTick();
        expect(wrapper.emitted('filter-change')).toStrictEqual([
          [{ ...DEFAULT_FILTERS, searchTerm }],
        ]);
      });
    });
  });

  describe('Status Filter', () => {
    it('Displays the "All" status if no statuses are selected', () => {
      createWrapper({ method: mount, filters: { statuses: [] } });
      expect(findDropdownMessage()).toBe(ALL.value);
    });

    it('Displays the status if only one status is selected', () => {
      const status = 'TRIGGERED';
      const translated = STATUSES[status];
      createWrapper({ method: mount, filters: { statuses: [status] } });
      expect(findDropdownMessage()).toBe(translated);
    });

    it('Displays the additional text if more than one status is selected', () => {
      const status = 'TRIGGERED';
      const translated = STATUSES[status];
      createWrapper({ method: mount });
      expect(trimText(findDropdownMessage())).toBe(`${translated} +1 more`);
    });

    it('Emits an event with the new filters on deselect', async () => {
      createWrapper({});
      clickDropdownItemAtIndex(2);
      expect(wrapper.emitted('filter-change')).toHaveLength(1);
      expect(wrapper.emitted('filter-change')[0][0]).toStrictEqual({ statuses: ['TRIGGERED'] });
    });

    it('Emits an event with the new filters on a select', () => {
      createWrapper({});
      clickDropdownItemAtIndex(4);
      expect(wrapper.emitted('filter-change')).toHaveLength(1);
      expect(wrapper.emitted('filter-change')[0][0]).toStrictEqual({
        statuses: ['TRIGGERED', 'ACKNOWLEDGED', 'IGNORED'],
      });
    });

    it('Emits an event with no filters on a select of all the filters', () => {
      const MOST_STATUSES = [...Object.keys(STATUSES)].slice(1);
      createWrapper({ filters: { statuses: MOST_STATUSES } });
      clickDropdownItemAtIndex(1);
      expect(wrapper.emitted('filter-change')).toHaveLength(1);
      expect(wrapper.emitted('filter-change')[0][0]).toStrictEqual({ statuses: [] });
    });

    it('Checks "All" filter if no statuses are selected', () => {
      createWrapper({ filters: { statuses: [] } });
      expect(findDropdownItemAtIndex(0).props('isChecked')).toBe(true);
    });

    it('Unchecks "All" filter if a status is selected', () => {
      createWrapper({});
      expect(findDropdownItemAtIndex(0).props('isChecked')).toBe(false);
    });
  });
});
