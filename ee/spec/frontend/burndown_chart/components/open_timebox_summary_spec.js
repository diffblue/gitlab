import { shallowMount } from '@vue/test-utils';
import OpenTimeboxSummary from 'ee/burndown_chart/components/open_timebox_summary.vue';

describe('Iterations report summary', () => {
  let slotSpy;

  const id = 3;
  const defaultProps = {
    fullPath: 'gitlab-org',
    iterationId: `gid://gitlab/Iteration/${id}`,
  };

  const mountComponent = ({ props = defaultProps, loading = false, data = {} } = {}) => {
    slotSpy = jest.fn();

    shallowMount(OpenTimeboxSummary, {
      propsData: props,
      data() {
        return data;
      },
      mocks: {
        $apollo: {
          queries: { issues: { loading } },
        },
      },
      scopedSlots: {
        default: slotSpy,
      },
    });
  };

  describe('with valid totals', () => {
    beforeEach(() => {
      mountComponent({
        data: {
          issues: {
            closed: 10,
            assigned: 3,
            open: 5,
          },
        },
      });
    });

    it('passes data to cards component', () => {
      expect(slotSpy).toHaveBeenCalledWith({
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
            value: 5,
          },
        ],
        total: 18,
      });
    });
  });
});
