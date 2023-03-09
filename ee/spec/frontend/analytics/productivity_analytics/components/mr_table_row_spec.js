import { GlAvatar } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MetricColumn from 'ee/analytics/productivity_analytics/components/metric_column.vue';
import MergeRequestTableRow from 'ee/analytics/productivity_analytics/components/mr_table_row.vue';
import { mockMergeRequests } from '../mock_data';

describe('MergeRequestTableRow component', () => {
  let wrapper;

  const defaultProps = {
    mergeRequest: mockMergeRequests[0],
    metricType: 'time_to_last_commit',
    metricLabel: 'Time from first comment to last commit',
  };

  const factory = (props = defaultProps) => {
    wrapper = shallowMount(MergeRequestTableRow, {
      propsData: { ...props },
    });
  };

  const findMrDetails = () => wrapper.find('.js-mr-details');
  const findMrMetrics = () => wrapper.find('.js-mr-metrics');
  const findMetricColumns = () => findMrMetrics().findAllComponents(MetricColumn);

  describe('on creation', () => {
    beforeEach(() => {
      factory();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('template', () => {
    beforeEach(() => {
      factory();
    });

    it('renders the avatar with correct URL', () => {
      const avatar = wrapper.findComponent(GlAvatar);

      expect(avatar.exists()).toBe(true);
      expect(avatar.props('src')).toEqual(defaultProps.mergeRequest.author_avatar_url);
    });

    it('renders the merge request title', () => {
      const title = findMrDetails().find('.item-title');

      expect(title.exists()).toBe(true);
      expect(title.text()).toContain(defaultProps.mergeRequest.title);
    });

    describe('metric list', () => {
      it.each`
        metric              | selector
        ${'commits_count'}  | ${'commitCount'}
        ${'loc_per_commit'} | ${'locPerCommitCount'}
        ${'files_touched'}  | ${'filesTouchedCount'}
      `("metric '$metric' won't be rendered if null", ({ metric, selector }) => {
        // let's update our test data and set the metric to null
        const props = {
          ...defaultProps,
          mergeRequest: {
            ...defaultProps.mergeRequest,
            [metric]: null,
          },
        };
        factory(props);
        expect(wrapper.findComponent({ ref: selector }).exists()).toBe(false);
      });
    });

    describe('metric columns', () => {
      it('renders two metric columns', () => {
        expect(findMetricColumns()).toHaveLength(2);
      });

      it('renders the "Time to merge" metric column with the "days_to_merge" metric', () => {
        expect(findMetricColumns().at(0).props('value')).toBe(
          defaultProps.mergeRequest.days_to_merge,
        );
      });
    });
  });

  describe('computed', () => {
    describe('mrId', () => {
      beforeEach(() => {
        factory();
      });

      it('returns the merge request ID with a leading "!"', () => {
        expect(wrapper.vm.mrId).toBe(`!${defaultProps.mergeRequest.iid}`);
      });
    });

    describe('commitCount', () => {
      beforeEach(() => {
        factory();
      });

      it('returns the number of commits', () => {
        expect(wrapper.vm.commitCount).toBe(`${defaultProps.mergeRequest.commits_count} commit`);
      });
    });

    describe('locPerCommit', () => {
      beforeEach(() => {
        factory();
      });

      it('returns the LOC per commit', () => {
        expect(wrapper.vm.locPerCommit).toBe(
          `${defaultProps.mergeRequest.loc_per_commit} LOC/commit`,
        );
      });
    });

    describe('filesTouched', () => {
      beforeEach(() => {
        factory();
      });

      it('returns the number of files touched', () => {
        expect(wrapper.vm.filesTouched).toBe(
          `${defaultProps.mergeRequest.files_touched} files touched`,
        );
      });
    });

    describe('selectedMetric', () => {
      beforeEach(() => {
        factory();
      });

      it("returns the selected metric's key", () => {
        expect(wrapper.vm.selectedMetric).toBe(defaultProps.mergeRequest[defaultProps.metricType]);
      });
    });
  });
});
