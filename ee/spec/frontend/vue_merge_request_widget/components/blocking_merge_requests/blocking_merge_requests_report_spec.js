import { shallowMount, config } from '@vue/test-utils';
import BlockingMergeRequestsReport from 'ee/vue_merge_request_widget/components/blocking_merge_requests/blocking_merge_requests_report.vue';
import ReportSection from '~/ci/reports/components/report_section.vue';
import { status as reportStatus } from '~/ci/reports/constants';

describe('BlockingMergeRequestsReport', () => {
  let wrapper;
  let props;

  // Remove these hooks once we update @vue/test-utils
  // See this issue: https://github.com/vuejs/vue-test-utils/issues/973
  beforeAll(() => {
    config.logModifiedComponents = false;
  });

  afterAll(() => {
    config.logModifiedComponents = true;
  });

  beforeEach(() => {
    props = {
      mr: {
        blockingMergeRequests: {
          total_count: 3,
          hidden_count: 0,
          visible_merge_requests: {
            opened: [{ id: 1, state: 'opened' }],
            closed: [{ id: 2, state: 'closed' }],
            merged: [{ id: 3, state: 'merged' }],
          },
        },
      },
    };
  });

  const createComponent = (propsData = props) => {
    wrapper = shallowMount(BlockingMergeRequestsReport, {
      propsData,
    });
  };

  it('does not render blocking merge requests report if no blocking MRs exist', () => {
    props.mr.blockingMergeRequests.total_count = 0;
    props.mr.blockingMergeRequests.visible_merge_requests = {};
    createComponent(props);

    expect(wrapper.html()).toBe('');
  });

  it('passes merged MRs as resolved issues and anything else as unresolved', () => {
    createComponent();
    const reportSectionProps = wrapper.findComponent(ReportSection).props();

    expect(reportSectionProps.resolvedIssues).toHaveLength(1);
    expect(reportSectionProps.resolvedIssues[0].id).toBe(3);
  });

  it('passes all non "merged" MRs as unresolved issues', () => {
    createComponent();
    const reportSectionProps = wrapper.findComponent(ReportSection).props();

    expect(reportSectionProps.unresolvedIssues.map((issue) => issue.id)).toEqual([2, 1]);
  });

  it('sets status to "ERROR" when there are unmerged blocking MRs', () => {
    createComponent();

    expect(wrapper.findComponent(ReportSection).props().status).toBe(reportStatus.ERROR);
  });

  it('sets status to "SUCCESS" when all blocking MRs are merged', () => {
    props.mr.blockingMergeRequests.total_count = 1;
    props.mr.blockingMergeRequests.visible_merge_requests = {
      merged: [{ id: 3, state: 'merged' }],
    };
    createComponent();

    expect(wrapper.findComponent(ReportSection).props().status).toBe(reportStatus.SUCCESS);
  });

  describe('blockedByText', () => {
    it('contains closed information if some  are closed, but not all', () => {
      createComponent();

      expect(wrapper.vm.blockedByText).toBe(
        'Depends on 2 merge requests being merged %{strongStart}(1 closed)%{strongEnd}',
      );
    });

    it('does not contain closed information if no blocking MRs are closed', () => {
      delete props.mr.blockingMergeRequests.visible_merge_requests.closed;
      createComponent();

      expect(wrapper.vm.blockedByText).not.toContain('closed');
    });

    it('states when all blocking mrs are closed', () => {
      delete props.mr.blockingMergeRequests.visible_merge_requests.opened;
      createComponent();

      expect(wrapper.vm.blockedByText).toEqual(
        'Depends on %{strongStart}1 closed%{strongEnd} merge request.',
      );
    });
  });

  describe('unmergedBlockingMergeRequests', () => {
    it('does not include merged MRs', () => {
      createComponent();
      const containsMergedMRs = wrapper.vm.unmergedBlockingMergeRequests.some(
        (mr) => mr.state === 'merged',
      );

      expect(containsMergedMRs).toBe(false);
    });

    it('puts closed MRs first', () => {
      createComponent();
      const closedIndex = wrapper.vm.unmergedBlockingMergeRequests.findIndex(
        (mr) => mr.state === 'closed',
      );

      expect(closedIndex).toBe(0);
    });
  });
});
