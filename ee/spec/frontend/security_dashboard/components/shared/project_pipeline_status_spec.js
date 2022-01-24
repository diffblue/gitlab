import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { merge } from 'lodash';
import PipelineStatusBadge from 'ee/security_dashboard/components/shared/pipeline_status_badge.vue';
import ProjectPipelineStatus from 'ee/security_dashboard/components/shared/project_pipeline_status.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

describe('Project Pipeline Status Component', () => {
  let wrapper;

  const DEFAULT_PROPS = {
    pipeline: {
      createdAt: '2020-10-06T20:08:07Z',
      id: '214',
      path: '/mixed-vulnerabilities/dependency-list-test-01/-/pipelines/214',
    },
  };

  const findPipelineStatusBadge = () => wrapper.findComponent(PipelineStatusBadge);
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const findLink = () => wrapper.findComponent(GlLink);
  const findAutoFixMrsLink = () => wrapper.findByTestId('auto-fix-mrs-link');

  const createWrapper = (options = {}) => {
    return extendedWrapper(
      shallowMount(
        ProjectPipelineStatus,
        merge(
          {},
          {
            propsData: DEFAULT_PROPS,
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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default state', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('should show the timeAgoTooltip component', () => {
      const TimeComponent = findTimeAgoTooltip();
      expect(TimeComponent.exists()).toBeTruthy();
      expect(TimeComponent.props()).toStrictEqual({
        time: DEFAULT_PROPS.pipeline.createdAt,
        cssClass: '',
        tooltipPlacement: 'top',
      });
    });

    it('should show the link component', () => {
      const GlLinkComponent = findLink();
      expect(GlLinkComponent.exists()).toBeTruthy();
      expect(GlLinkComponent.text()).toBe(`#${DEFAULT_PROPS.pipeline.id}`);
      expect(GlLinkComponent.attributes('href')).toBe(DEFAULT_PROPS.pipeline.path);
    });
  });

  describe('when no pipeline has run', () => {
    beforeEach(() => {
      wrapper = createWrapper({ propsData: { pipeline: { path: '' } } });
    });

    it('should not show the project_pipeline_status component', () => {
      expect(findLink().exists()).toBe(false);
      expect(findTimeAgoTooltip().exists()).toBe(false);
      expect(findPipelineStatusBadge().exists()).toBe(false);
    });
  });

  describe('auto-fix MRs', () => {
    describe('when there are auto-fix MRs', () => {
      beforeEach(() => {
        wrapper = createWrapper({
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
      wrapper = createWrapper();

      expect(findAutoFixMrsLink().exists()).toBe(false);
    });
  });
});
