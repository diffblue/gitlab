import { GlFilteredSearch } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import AuditEventsFilter from 'ee/audit_events/components/audit_events_filter.vue';
import { AVAILABLE_TOKEN_TYPES } from 'ee/audit_events/constants';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';

describe('AuditEventsFilter', () => {
  let wrapper;

  const value = [{ type: 'project', value: { data: 1, operator: '=' } }];
  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const getAvailableTokens = () => findFilteredSearch().props('availableTokens');
  const getAvailableTokenProps = (type) =>
    getAvailableTokens().find((token) => token.type === type);

  const initComponent = (props = {}) => {
    wrapper = shallowMount(AuditEventsFilter, {
      propsData: {
        ...props,
      },
    });
  };

  describe.each`
    type         | title
    ${'project'} | ${'Project Events'}
    ${'group'}   | ${'Group Events'}
    ${'user'}    | ${'User Events'}
    ${'member'}  | ${'Member Events'}
  `('for the list of available tokens', ({ type, title }) => {
    it(`creates a unique token for ${type}`, () => {
      initComponent();
      expect(getAvailableTokenProps(type)).toMatchObject({
        title,
        unique: true,
        operators: OPERATORS_IS,
      });
    });
  });

  describe('when the default token value is set', () => {
    beforeEach(() => {
      initComponent({ value });
    });

    it('sets the filtered searched token', () => {
      expect(findFilteredSearch().props('value')).toEqual(value);
    });

    it('only one token matching the selected token type is enabled', () => {
      expect(getAvailableTokenProps('project').disabled).toEqual(false);
      expect(getAvailableTokenProps('group').disabled).toEqual(true);
      expect(getAvailableTokenProps('user').disabled).toEqual(true);
    });

    describe('and the user submits the search field', () => {
      beforeEach(() => {
        findFilteredSearch().vm.$emit('submit');
      });

      it('should emit the "submit" event', () => {
        expect(wrapper.emitted().submit).toHaveLength(1);
      });
    });
  });

  describe('when the default token value is not set', () => {
    beforeEach(() => {
      initComponent();
    });

    it('has an empty search value', () => {
      expect(findFilteredSearch().vm.value).toEqual([]);
    });

    describe('and the user inputs nothing into the search field', () => {
      beforeEach(() => {
        findFilteredSearch().vm.$emit('input', []);
      });

      it('should emit the "selected" event with empty values', () => {
        expect(wrapper.emitted().selected[0]).toEqual([[]]);
      });

      describe('and the user submits the search field', () => {
        beforeEach(() => {
          findFilteredSearch().vm.$emit('submit');
        });

        it('should emit the "submit" event', () => {
          expect(wrapper.emitted().submit).toHaveLength(1);
        });
      });
    });
  });

  describe('when enabling just a single token type', () => {
    const type = AVAILABLE_TOKEN_TYPES[0];

    beforeEach(() => {
      initComponent({
        filterTokenOptions: [{ type }],
      });
    });

    it('only the enabled tokens type is available for selection', () => {
      expect(getAvailableTokens().length).toEqual(1);
      expect(getAvailableTokens()).toMatchObject([{ type }]);
    });
  });

  describe('view-only state', () => {
    it.each([true, false])(
      'passes the view-only value to the filtered search component when %s',
      (viewOnly) => {
        initComponent({ viewOnly });

        expect(findFilteredSearch().props('viewOnly')).toBe(viewOnly);
      },
    );
  });
});
