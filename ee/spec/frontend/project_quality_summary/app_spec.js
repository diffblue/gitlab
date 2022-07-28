import { GlSkeletonLoader, GlEmptyState } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import mockProjectQualityResponse from 'test_fixtures/graphql/project_quality_summary/graphql/queries/get_project_quality.query.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import { mountExtended } from 'helpers/vue_test_utils_helper';

import ProjectQualitySummary from 'ee/project_quality_summary/app.vue';
import FeedbackBanner from 'ee/project_quality_summary/components/feedback_banner.vue';
import getProjectQuality from 'ee/project_quality_summary/graphql/queries/get_project_quality.query.graphql';
import { i18n } from 'ee/project_quality_summary/constants';

jest.mock('~/flash');

Vue.use(VueApollo);

describe('Project quality summary app component', () => {
  let wrapper;

  const findTestRunsLink = () => wrapper.findByTestId('test-runs-link');
  const findTestRunsStat = (index) => wrapper.findAllByTestId('test-runs-stat').at(index);
  const findCoverageLink = () => wrapper.findByTestId('coverage-link');
  const findCoverageStat = () => wrapper.findByTestId('coverage-stat');
  const findBanner = () => wrapper.findComponent(FeedbackBanner);

  const coverageChartPath = 'coverage/chart/path';
  const { pipelinePath, coverage } = mockProjectQualityResponse.data.project.pipelines.nodes[0];

  const createComponent = (
    mockReturnValue = jest.fn().mockResolvedValue(mockProjectQualityResponse),
  ) => {
    const apolloProvider = createMockApollo([[getProjectQuality, mockReturnValue]]);

    wrapper = mountExtended(ProjectQualitySummary, {
      apolloProvider,
      provide: {
        projectPath: 'project-path',
        coverageChartPath,
        defaultBranch: 'main',
        testRunsEmptyStateImagePath: 'image/path',
        projectQualitySummaryFeedbackImagePath: 'banner/image/path',
      },
    });
  };

  describe('when loading', () => {
    beforeEach(() => {
      createComponent(jest.fn().mockReturnValueOnce(new Promise(() => {})));
    });

    it('shows a loading state', () => {
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });
  });

  describe('on error', () => {
    beforeEach(async () => {
      createComponent(jest.fn().mockRejectedValueOnce(new Error('Error!')));
      await waitForPromises();
    });

    it('shows a flash message', () => {
      expect(createFlash).toHaveBeenCalled();
    });
  });

  describe('feedback banner', () => {
    it('is rendered', () => {
      createComponent();

      expect(findBanner().exists()).toBe(true);
    });
  });

  describe('with data', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    describe('test runs card', () => {
      it('shows a link to the full report', () => {
        expect(findTestRunsLink().attributes('href')).toBe(`${pipelinePath}/test_report`);
      });

      it('shows the percentage of tests that passed', () => {
        const passedStat = findTestRunsStat(0).text();

        expect(passedStat).toContain('Passed');
        expect(passedStat).toContain(' 50%');
      });

      it('shows the percentage of tests that failed', () => {
        const failedStat = findTestRunsStat(1).text();

        expect(failedStat).toContain('Failed');
        expect(failedStat).toContain(' 0%');
      });

      it('shows the percentage of tests that were skipped', () => {
        const skippedStat = findTestRunsStat(2).text();

        expect(skippedStat).toContain('Skipped');
        expect(skippedStat).toContain(' 0%');
      });
    });

    describe('test coverage card', () => {
      it('shows a link to coverage charts', () => {
        expect(findCoverageLink().attributes('href')).toBe(coverageChartPath);
      });

      it('shows the coverage percentage', () => {
        expect(findCoverageStat().text()).toContain(`${coverage}%`);
      });
    });
  });

  describe('without data', () => {
    beforeEach(async () => {
      createComponent(jest.fn().mockResolvedValue([]));
      await waitForPromises();
    });

    it('shows a test runs empty state', () => {
      const emptyState = wrapper.findComponent(GlEmptyState);

      expect(emptyState.exists()).toBe(true);
      expect(emptyState.text()).toContain(i18n.testRuns.title);
      expect(emptyState.text()).toContain(i18n.testRuns.emptyStateDescription);
      expect(emptyState.text()).toContain(i18n.testRuns.emptyStateLink);
    });
  });
});
