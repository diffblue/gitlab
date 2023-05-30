import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import CiEditorHeader from 'ee/ci/pipeline_editor/components/editor/ci_editor_header.vue';
import CiEditorHeaderCE from '~/ci/pipeline_editor/components/editor/ci_editor_header.vue';

import { pipelineEditorTrackingOptions } from '~/ci/pipeline_editor/constants';

describe('CI Editor Header', () => {
  let wrapper;
  let trackingSpy = null;

  const defaultProps = {
    showDrawer: false,
    showJobAssistantDrawer: false,
    showAiAssistantDrawer: false,
  };

  const defaultProvide = {
    canViewNamespaceCatalog: true,
    ciCatalogPath: '/ci/catalog/resources',
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(CiEditorHeader, {
      provide: {
        ...defaultProvide,
      },
      propsData: {
        ...defaultProps,
      },
    });
  };

  const findCEHeader = () => wrapper.findComponent(CiEditorHeaderCE);
  const findCatalogRepoLinkButton = () => wrapper.findByTestId('catalog-repo-link');

  beforeEach(() => {
    createComponent();
  });

  const testTracker = async (element, expectedAction) => {
    const { label } = pipelineEditorTrackingOptions;

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    await element.vm.$emit('click');

    expect(trackingSpy).toHaveBeenCalledWith(undefined, expectedAction, {
      label,
    });
  };

  describe('CE passthrough', () => {
    it('renders the CE header', () => {
      expect(findCEHeader().exists()).toBe(true);
    });

    it('passes down all props to CE header', () => {
      expect(findCEHeader().props()).toEqual(defaultProps);
    });
  });

  describe('component repo link button', () => {
    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('finds the browse template button', () => {
      expect(findCatalogRepoLinkButton().exists()).toBe(true);
    });

    it('contains the link to the template repo', () => {
      expect(findCatalogRepoLinkButton().attributes('href')).toBe(defaultProvide.ciCatalogPath);
    });

    it('has the external-link icon', () => {
      expect(findCatalogRepoLinkButton().props('icon')).toBe('external-link');
    });

    it('tracks the click on the browse button', () => {
      const { browseCatalog } = pipelineEditorTrackingOptions.actions;

      testTracker(findCatalogRepoLinkButton(), browseCatalog);
    });
  });
});
