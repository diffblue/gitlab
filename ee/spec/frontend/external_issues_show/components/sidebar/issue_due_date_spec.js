import { shallowMount } from '@vue/test-utils';

import IssueDueDate from 'ee/external_issues_show/components/sidebar/issue_due_date.vue';

import { useFakeDate } from 'helpers/fake_date';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('IssueDueDate', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(IssueDueDate, {
        propsData: props,
      }),
    );
  };

  const findDueDateCollapsed = () => wrapper.findByTestId('due-date-collapsed');
  const findDueDateValue = () => wrapper.findByTestId('due-date-value');

  describe('when dueDate is null', () => {
    it('renders "None" as value', () => {
      createComponent();

      expect(findDueDateCollapsed().text()).toBe('None');
      expect(findDueDateValue().text()).toBe('None');
    });
  });

  describe('when dueDate is in the past', () => {
    const dueDate = '2021-02-14T00:00:00.000Z';

    useFakeDate(2021, 2, 18);

    it('renders formatted dueDate', () => {
      createComponent({
        props: {
          dueDate,
        },
      });

      expect(findDueDateCollapsed().text()).toBe('Feb 14, 2021');
      expect(findDueDateValue().text()).toBe('Feb 14, 2021 (Past due)');
    });
  });

  describe('when dueDate is in the future', () => {
    const dueDate = '2021-02-14T00:00:00.000Z';

    useFakeDate(2020, 12, 20);

    it('renders formatted dueDate', () => {
      createComponent({
        props: {
          dueDate,
        },
      });

      expect(findDueDateCollapsed().text()).toBe('Feb 14, 2021');
      expect(findDueDateValue().text()).toBe('Feb 14, 2021');
    });
  });
});
