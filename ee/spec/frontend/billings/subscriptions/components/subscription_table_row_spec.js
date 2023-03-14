import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import SubscriptionTableRow from 'ee/billings/subscriptions/components/subscription_table_row.vue';
import initialStore from 'ee/billings/subscriptions/store';
import { TABLE_TYPE_DEFAULT } from 'ee/billings/constants';
import { dateInWords } from '~/lib/utils/datetime_utility';
import Popover from '~/vue_shared/components/help_popover.vue';

Vue.use(Vuex);

describe('subscription table row', () => {
  let store;
  let wrapper;

  const HEADER = {
    icon: 'monitor',
    title: 'Test title',
  };

  const COLUMNS = [
    {
      id: 'a',
      label: 'Column A',
      value: 100,
      colClass: 'number',
    },
    {
      id: 'b',
      label: 'Column B',
      value: 200,
      popover: {
        content: 'This is a tooltip',
      },
    },
  ];

  const BILLABLE_SEATS_URL = 'http://billable/seats';

  const defaultProps = { header: HEADER, columns: COLUMNS };

  const createComponent = ({
    props = {},
    billableSeatsHref = BILLABLE_SEATS_URL,
    seatsLastUpdated = '12:13:14',
  } = {}) => {
    wrapper = shallowMount(SubscriptionTableRow, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        billableSeatsHref,
        seatsLastUpdated,
      },
      store,
    });
  };

  beforeEach(() => {
    store = new Vuex.Store(initialStore());
    jest.spyOn(store, 'dispatch').mockImplementation();
  });

  const findHeaderCell = () => wrapper.find('[data-testid="header-cell"]');
  const findContentCells = () => wrapper.findAll('[data-testid="content-cell"]');
  const findHeaderIcon = () => findHeaderCell().findComponent(GlIcon);

  const findColumnLabelAndTitle = (columnWrapper) => {
    const label = columnWrapper.find('[data-testid="property-label"]');
    const value = columnWrapper.find('[data-testid="property-value"]');

    return expect.objectContaining({
      label: label.text(),
      value: Number(value.text()),
    });
  };

  const findUsageButton = () => findContentCells().at(0).find('[data-testid="seats-usage-button"]');

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it(`should render one header cell and ${COLUMNS.length} visible columns in total`, () => {
      expect(findHeaderCell().isVisible()).toBe(true);
      expect(findContentCells()).toHaveLength(COLUMNS.length);
    });

    it(`should not render a hidden column`, () => {
      const hiddenColIdx = COLUMNS.find((c) => !c.display);
      const hiddenCol = findContentCells().at(hiddenColIdx);

      expect(hiddenCol).toBe(undefined);
    });

    it('should render a title in the header cell', () => {
      expect(findHeaderCell().text()).toMatch(HEADER.title);
    });

    it(`should render a ${HEADER.icon} icon in the header cell`, () => {
      expect(findHeaderIcon().exists()).toBe(true);
      expect(findHeaderIcon().props('name')).toBe(HEADER.icon);
    });

    it('renders correct column structure', () => {
      const columnsStructure = findContentCells().wrappers.map(findColumnLabelAndTitle);

      expect(columnsStructure).toEqual(expect.arrayContaining(COLUMNS));
    });

    it('should append the "number" css class to property value in "Column A"', () => {
      const currentCol = findContentCells().at(0);

      expect(
        currentCol.find('[data-testid="property-value"]').element.classList.contains('number'),
      ).toBe(true);
    });

    it('should render an info icon in "Column B"', () => {
      const currentCol = findContentCells().at(1);

      expect(currentCol.findComponent(Popover).exists()).toBe(true);
    });
  });

  describe('seats last updated time', () => {
    it.each([
      {
        columns: [
          {
            id: 'seatsInSubscription',
            label: 'Column A',
            value: 100,
            colClass: 'number',
            type: TABLE_TYPE_DEFAULT,
          },
        ],
        description: 'type is default and column id is seatsInSubscription',
        expected: 'Up to date',
      },
      {
        columns: [
          {
            id: 'a',
            label: 'Column A',
            value: 100,
            colClass: 'number',
            type: TABLE_TYPE_DEFAULT,
          },
        ],
        description: 'type is default and column id is not seatsInSubscription',
        expected: 'Last updated at 12:13:14 UTC',
      },
    ])('renders seats last updated time when $description', ({ columns, expected }) => {
      createComponent({ props: { columns } });

      expect(wrapper.find('[data-testid="seats-last-updated"]').text()).toBe(expected);
    });

    it('does not render seats last updated block when table type is not default', () => {
      createComponent({
        seatsLastUpdated: '',
        props: {
          columns: [
            {
              id: 'seatsInSubscription',
              label: 'Column A',
              value: 100,
              colClass: 'number',
              type: TABLE_TYPE_DEFAULT,
            },
          ],
        },
      });

      expect(wrapper.find('[data-testid="seats-last-updated"]').exists()).toBe(false);
    });

    it('does not render seats last updated block when seatsLastUpdated is not available', () => {
      createComponent({
        props: {
          columns: [
            {
              id: 'a',
              label: 'Column A',
              value: 100,
              colClass: 'number',
            },
          ],
        },
      });

      expect(wrapper.find('[data-testid="seats-last-updated"]').exists()).toBe(false);
    });
  });

  describe('with free plan', () => {
    const dateColumn = {
      id: 'a',
      label: 'Column A',
      value: 0,
      colClass: 'number',
    };

    it('renders a dash when the value is zero', () => {
      createComponent({ props: { isFreePlan: true, columns: [dateColumn] } });

      expect(wrapper.find('[data-testid="property-value"]').text()).toBe('-');
    });
  });

  describe('date column', () => {
    const dateColumn = {
      id: 'c',
      label: 'Column C',
      value: '2018-01-31',
      isDate: true,
    };

    beforeEach(() => {
      createComponent({ props: { columns: [dateColumn] } });
    });

    it('should render the date in UTC', () => {
      const currentCol = findContentCells().at(0);

      const d = dateColumn.value.split('-');
      const outputDate = dateInWords(new Date(d[0], d[1] - 1, d[2]));

      expect(currentCol.find('[data-testid="property-label"]').text()).toMatch(dateColumn.label);
      expect(currentCol.find('[data-testid="property-value"]').text()).toMatch(outputDate);
    });
  });

  describe('seats in use button', () => {
    it.each`
      columnId        | provide                        | exists   | attrs
      ${'seatsInUse'} | ${{}}                          | ${true}  | ${{ href: BILLABLE_SEATS_URL }}
      ${'seatsInUse'} | ${{ billableSeatsHref: '' }}   | ${false} | ${{}}
      ${'some_value'} | ${{}}                          | ${false} | ${{}}
      ${'seatsInUse'} | ${{ billableSeatsHref: null }} | ${false} | ${{}}
    `(
      'should exists=$exists with (columnId=$columnId, provide=$provide)',
      ({ columnId, provide, exists, attrs }) => {
        createComponent({ props: { columns: [{ id: columnId }] }, ...provide });

        expect(findUsageButton().exists()).toBe(exists);
        if (exists) {
          expect(findUsageButton().attributes()).toMatchObject(attrs);
        }
      },
    );
  });
});
