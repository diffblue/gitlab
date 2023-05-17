import { GlSkeletonLoader } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import GroupActivityCard from 'ee/analytics/group_analytics/components/group_activity_card.vue';
import Api from 'ee/api';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const TEST_GROUP_ID = 'gitlab-org';
const TEST_GROUP_NAME = 'Gitlab Org';
const TEST_MERGE_REQUESTS_METRIC_LINK = `/groups/${TEST_GROUP_ID}/-/analytics/productivity_analytics`;
const TEST_ISSUES_METRIC_LINK = `/groups/${TEST_GROUP_ID}/-/issues_analytics`;
const TEST_NEW_MEMBERS_METRIC_LINK = `/groups/${TEST_GROUP_ID}/-/group_members?sort=last_joined`;
const TEST_MERGE_REQUESTS_COUNT = { data: { merge_requests_count: 10 } };
const TEST_LARGE_MERGE_REQUESTS_COUNT = { data: { merge_requests_count: 1001 } };
const TEST_ISSUES_COUNT = { data: { issues_count: 20 } };
const TEST_LARGE_ISSUES_COUNT = { data: { issues_count: 999 } };
const TEST_NEW_MEMBERS_COUNT = { data: { new_members_count: 30 } };
const TEST_LARGE_NEW_MEMBERS_COUNT = { data: { new_members_count: 998 } };

const mockActivityRequests = ({ issuesCount, mergeRequestsCount, newMembersCount }) => {
  jest
    .spyOn(Api, 'groupActivityMergeRequestsCount')
    .mockReturnValue(Promise.resolve(mergeRequestsCount));

  jest.spyOn(Api, 'groupActivityIssuesCount').mockReturnValue(Promise.resolve(issuesCount));

  jest.spyOn(Api, 'groupActivityNewMembersCount').mockReturnValue(Promise.resolve(newMembersCount));
};

describe('GroupActivity component', () => {
  let wrapper;
  let mock;

  const createComponent = () => {
    wrapper = extendedWrapper(
      mount(GroupActivityCard, {
        provide: {
          groupFullPath: TEST_GROUP_ID,
          groupName: TEST_GROUP_NAME,
          mergeRequestsMetricLink: TEST_MERGE_REQUESTS_METRIC_LINK,
          issuesMetricLink: TEST_ISSUES_METRIC_LINK,
          newMembersMetricLink: TEST_NEW_MEMBERS_METRIC_LINK,
        },
      }),
    );
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    mockActivityRequests({
      issuesCount: TEST_ISSUES_COUNT,
      mergeRequestsCount: TEST_MERGE_REQUESTS_COUNT,
      newMembersCount: TEST_NEW_MEMBERS_COUNT,
    });
  });

  afterEach(() => {
    mock.restore();
  });

  const findAllSkeletonLoaders = () => wrapper.findAllComponents(GlSkeletonLoader);
  const findAllSingleStatAnchors = () => wrapper.findAllByTestId('single-stat-link');
  const findAllSingleStats = () => wrapper.findAllComponents(GlSingleStat);

  it('fetches the metrics and updates isLoading properly', async () => {
    createComponent();

    expect(wrapper.vm.isLoading).toBe(true);

    await nextTick();
    expect(Api.groupActivityMergeRequestsCount).toHaveBeenCalledWith(TEST_GROUP_ID);
    expect(Api.groupActivityIssuesCount).toHaveBeenCalledWith(TEST_GROUP_ID);
    expect(Api.groupActivityNewMembersCount).toHaveBeenCalledWith(TEST_GROUP_ID);

    await waitForPromises();
    expect(wrapper.vm.isLoading).toBe(false);
    expect(wrapper.vm.metrics.mergeRequests.value).toBe(10);
    expect(wrapper.vm.metrics.issues.value).toBe(20);
    expect(wrapper.vm.metrics.newMembers.value).toBe(30);
  });

  it('updates the loading state properly', async () => {
    createComponent();

    expect(findAllSkeletonLoaders()).toHaveLength(3);

    await nextTick();
    await waitForPromises();
    expect(findAllSkeletonLoaders()).toHaveLength(0);
  });

  describe('metrics', () => {
    describe.each`
      index | value | title                       | link
      ${0}  | ${10} | ${'Merge requests created'} | ${TEST_MERGE_REQUESTS_METRIC_LINK}
      ${1}  | ${20} | ${'Issues created'}         | ${TEST_ISSUES_METRIC_LINK}
      ${2}  | ${30} | ${'Members added'}          | ${TEST_NEW_MEMBERS_METRIC_LINK}
    `('for metric $title', ({ index, value, title, link }) => {
      beforeEach(() => {
        createComponent();
      });

      it('renders a GlSingleStat', () => {
        const singleStat = findAllSingleStats().at(index);
        expect(singleStat.props('value')).toBe(`${value}`);
        expect(singleStat.props('title')).toBe(title);
      });

      it('redirects to the link on click', () => {
        const anchor = findAllSingleStatAnchors().at(index);
        expect(anchor.attributes('href')).toBe(link);
      });
    });
  });

  describe('with large values', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);

      mockActivityRequests({
        issuesCount: TEST_LARGE_ISSUES_COUNT,
        mergeRequestsCount: TEST_LARGE_MERGE_REQUESTS_COUNT,
        newMembersCount: TEST_LARGE_NEW_MEMBERS_COUNT,
      });

      createComponent();
    });

    it.each`
      index | value     | title
      ${0}  | ${'999+'} | ${'Merge requests created'}
      ${1}  | ${999}    | ${'Issues created'}
      ${2}  | ${998}    | ${'Members added'}
    `('renders a GlSingleStat for "$title"', ({ index, value, title }) => {
      const singleStat = findAllSingleStats().at(index);

      expect(singleStat.props('value')).toBe(`${value}`);
      expect(singleStat.props('title')).toBe(title);
    });
  });
});
