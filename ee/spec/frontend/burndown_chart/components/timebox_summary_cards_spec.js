import { GlCard } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import TimeboxSummaryCards from 'ee/burndown_chart/components/timebox_summary_cards.vue';

describe('Iterations report summary cards', () => {
  let wrapper;
  const defaultProps = {
    loading: false,
    columns: [
      {
        title: 'Completed',
        value: 10,
      },
      {
        title: 'Incomplete',
        value: 3,
      },
      {
        title: 'Unstarted',
        value: 2,
      },
    ],
    total: 15,
  };

  const mountComponent = (props = defaultProps) => {
    wrapper = mount(TimeboxSummaryCards, {
      propsData: props,
    });
  };

  const findCompleteCard = () => wrapper.findAllComponents(GlCard).at(0).text();
  const findIncompleteCard = () => wrapper.findAllComponents(GlCard).at(1).text();
  const findUnstartedCard = () => wrapper.findAllComponents(GlCard).at(2).text();

  describe('with valid totals', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('shows completed issues', () => {
      const text = findCompleteCard();

      expect(text).toContain('Completed');
      expect(text).toContain('67%');
      expect(text).toContain('10 of 15');
    });

    it('shows incomplete issues', () => {
      const text = findIncompleteCard();

      expect(text).toContain('Incomplete');
      expect(text).toContain('20%');
      expect(text).toContain('3 of 15');
    });

    it('shows unstarted issues', () => {
      const text = findUnstartedCard();

      expect(text).toContain('Unstarted');
      expect(text).toContain('13%');
      expect(text).toContain('2 of 15');
    });
  });

  it('shows 0 (not NaN) when total is 0', () => {
    mountComponent({
      loading: false,
      columns: [
        {
          title: 'Completed',
          value: 0,
        },
        {
          title: 'Incomplete',
          value: 0,
        },
        {
          title: 'Unstarted',
          value: 0,
        },
      ],
      total: 0,
    });

    expect(findCompleteCard()).toContain('0 of 0');
    expect(findIncompleteCard()).toContain('0 of 0');
    expect(findUnstartedCard()).toContain('0 of 0');
  });
});
