import { GlCollapsibleListbox, GlFormInput } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import NumberRangeSelect from 'ee/security_orchestration/components/policy_editor/scan_result/rule/number_range_select.vue';
import {
  ANY_OPERATOR,
  GREATER_THAN_OPERATOR,
  VULNERABILITIES_ALLOWED_OPERATORS,
} from 'ee/security_orchestration/components/policy_editor/constants';

describe('NumberRangeSelect', () => {
  let wrapper;

  const initialProps = {
    id: 'test-dropdown',
    value: 0,
    label: 'Test dropdown',
    operators: VULNERABILITIES_ALLOWED_OPERATORS,
  };

  const createComponent = (propsData = {}) => {
    wrapper = mountExtended(NumberRangeSelect, {
      propsData: {
        ...initialProps,
        ...propsData,
      },
    });
  };

  const findOperator = () => wrapper.findComponent(GlCollapsibleListbox);
  const findInput = () => wrapper.findComponent(GlFormInput);

  describe('initial rendering', () => {
    it.each`
      selected                 | inputExists
      ${ANY_OPERATOR}          | ${false}
      ${GREATER_THAN_OPERATOR} | ${true}
    `('renders input based on operator with', ({ selected, inputExists }) => {
      createComponent({ selected });

      const operator = findOperator();

      expect(operator.exists()).toBe(true);
      expect(findInput().exists()).toBe(inputExists);

      expect(operator.props('selected')).toBe(selected);
    });

    it('renders default operators', () => {
      createComponent();

      const itemValues = findOperator()
        .props('items')
        .map(({ value }) => value);

      expect(itemValues).toEqual([ANY_OPERATOR, GREATER_THAN_OPERATOR]);
    });

    it('can renders only the required operators', () => {
      createComponent({ operators: [{ value: GREATER_THAN_OPERATOR, text: 'greater than' }] });

      const itemValues = findOperator()
        .props('items')
        .map(({ value }) => value);

      expect(itemValues).toEqual([GREATER_THAN_OPERATOR]);
    });
  });

  describe('when changing operator value', () => {
    it('emits operator-change', () => {
      createComponent();

      expect(wrapper.emitted('operator-change')).toBeUndefined();

      findOperator().vm.$emit('select', GREATER_THAN_OPERATOR);

      expect(wrapper.emitted('operator-change')).toEqual([[GREATER_THAN_OPERATOR]]);
    });

    it('shows the number input when changing to GREATER_THAN_OPERATOR', async () => {
      createComponent({ selected: ANY_OPERATOR });

      await findOperator().vm.$emit('select', GREATER_THAN_OPERATOR);

      expect(findInput().exists()).toBe(true);
      expect(findInput().element.value).toEqual('0');
    });

    it('hides the number input when changing to ANY_OPERATOR', async () => {
      createComponent({ selected: GREATER_THAN_OPERATOR, value: 2 });

      await findOperator().vm.$emit('select', ANY_OPERATOR);

      expect(findInput().exists()).toBe(false);
    });
  });

  it('emits underlying input changes', async () => {
    createComponent({ selected: GREATER_THAN_OPERATOR, value: 2 });

    await findInput().vm.$emit('input', '3');

    expect(wrapper.emitted('input')).toEqual([[3]]);
  });
});
