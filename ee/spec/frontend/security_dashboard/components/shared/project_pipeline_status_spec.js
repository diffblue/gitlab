import { GlLink } from '@gitlab/ui';
import { merge } from 'lodash';
import { shallowMount } from '@vue/test-utils';
import PipelineStatusBadge from 'ee/security_dashboard/components/shared/pipeline_status_badge.vue';
import ProjectPipelineStatus from 'ee/security_dashboard/components/shared/project_pipeline_status.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { s__ } from '~/locale';
import { DEFAULT_DATE_TIME_FORMAT } from '~/lib/utils/datetime/constants';

const defaultPipeline = {
  createdAt: '2020-10-06T20:08:07Z',
  id: '214',
  path: '/mixed-vulnerabilities/dependency-list-test-01/-/pipelines/214',
};

const sbomPipeline = {
  createdAt: '2021-09-05T20:08:07Z',
  id: '245',
  path: '/mixed-vulnerabilities/dependency-list-test-01/-/pipelines/245',
};

describe('Project Pipeline Status Component', () => {
  let wrapper;

  const findPipelineStatusBadge = () =>
    wrapper.findByTestId('pipeline').findComponent(PipelineStatusBadge);
  const findTimeAgoTooltip = () => wrapper.findByTestId('pipeline').findComponent(TimeAgoTooltip);
  const findLink = () => wrapper.findByTestId('pipeline').findComponent(GlLink);
  const findSbomPipelineStatusBadge = () =>
    wrapper.findByTestId('sbom-pipeline').findComponent(PipelineStatusBadge);
  const findSbomTimeAgoTooltip = () =>
    wrapper.findByTestId('sbom-pipeline').findComponent(TimeAgoTooltip);
  const findSbomLink = () => wrapper.findByTestId('sbom-pipeline').findComponent(GlLink);
  const findParsingStatusNotice = () => wrapper.findByTestId('parsing-status-notice');
  const findAutoFixMrsLink = () => wrapper.findByTestId('auto-fix-mrs-link');

  const createWrapper = (options = {}) => {
    wrapper = extendedWrapper(
      shallowMount(
        ProjectPipelineStatus,
        merge(
          {
            propsData: {
              pipeline: defaultPipeline,
              sbomPipeline,
            },
            provide: {
              projectFullPath: '/group/project',
              glFeatures: { securityAutoFix: true },
              autoFixMrsPath: '/merge_requests?label_name=GitLab-auto-fix',
            },
            data() {
              return { autoFixMrsCount: 0 };
            },
          },
          options,
        ),
      ),
    );
  };

  describe('default state', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should show the timeAgoTooltip component', () => {
      const TimeComponent = findTimeAgoTooltip();
      expect(TimeComponent.exists()).toBe(true);
      expect(TimeComponent.props()).toStrictEqual({
        time: defaultPipeline.createdAt,
        cssClass: '',
        dateTimeFormat: DEFAULT_DATE_TIME_FORMAT,
        tooltipPlacement: 'top',
      });
    });

    it('should show the link component', () => {
      const GlLinkComponent = findLink();
      expect(GlLinkComponent.exists()).toBe(true);
      expect(GlLinkComponent.text()).toBe(`#${defaultPipeline.id}`);
      expect(GlLinkComponent.attributes('href')).toBe(defaultPipeline.path);
    });

    it('should show the pipeline status badge component', () => {
      expect(findPipelineStatusBadge().props('pipeline')).toBe(defaultPipeline);
    });
  });

  describe('parsing errors', () => {
    it('does not show a notice if there are no parsing errors', () => {
      createWrapper();

      expect(findParsingStatusNotice().exists()).toBe(false);
    });

    it.each`
      hasParsingErrors | hasParsingWarnings | expectedMessage
      ${true}          | ${true}            | ${s__('SecurityReports|Parsing errors and warnings in pipeline')}
      ${true}          | ${false}           | ${s__('SecurityReports|Parsing errors in pipeline')}
      ${false}         | ${true}            | ${s__('SecurityReports|Parsing warnings in pipeline')}
    `(
      'shows a notice if there are parsing errors',
      ({ hasParsingErrors, hasParsingWarnings, expectedMessage }) => {
        createWrapper({
          propsData: {
            pipeline: { hasParsingErrors, hasParsingWarnings },
          },
        });
        const parsingStatus = findParsingStatusNotice();

        expect(parsingStatus.exists()).toBe(true);
        expect(parsingStatus.text()).toBe(expectedMessage);
      },
    );
  });

  describe('auto-fix MRs', () => {
    describe('when there are auto-fix MRs', () => {
      beforeEach(() => {
        createWrapper({
          data() {
            return { autoFixMrsCount: 12 };
          },
        });
      });

      it('renders the auto-fix container', () => {
        expect(findAutoFixMrsLink().exists()).toBe(true);
      });

      it('renders a link to open auto-fix MRs if any', () => {
        const link = findAutoFixMrsLink().findComponent(GlLink);
        expect(link.exists()).toBe(true);
        expect(link.attributes('href')).toBe('/merge_requests?label_name=GitLab-auto-fix');
      });
    });

    it('does not render the link if there are no open auto-fix MRs', () => {
      createWrapper();

      expect(findAutoFixMrsLink().exists()).toBe(false);
    });
  });

  describe('sbom pipeline', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should show the timeAgoTooltip component', () => {
      const TimeComponent = findSbomTimeAgoTooltip();
      expect(TimeComponent.exists()).toBe(true);
      expect(TimeComponent.props()).toStrictEqual({
        time: sbomPipeline.createdAt,
        cssClass: '',
        dateTimeFormat: DEFAULT_DATE_TIME_FORMAT,
        tooltipPlacement: 'top',
      });
    });

    it('should show the link component', () => {
      const GlLinkComponent = findSbomLink();
      expect(GlLinkComponent.exists()).toBe(true);
      expect(GlLinkComponent.text()).toBe(`#${sbomPipeline.id}`);
      expect(GlLinkComponent.attributes('href')).toBe(sbomPipeline.path);
    });

    it('should show the pipeline status badge component', () => {
      expect(findSbomPipelineStatusBadge().props('pipeline')).toBe(sbomPipeline);
    });
  });
});
