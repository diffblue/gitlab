import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlTruncate } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';
import createMockApollo from 'helpers/mock_apollo_helper';
import ImageFilter from 'ee/security_dashboard/components/shared/filters/image_filter.vue';
import { IMAGE_FILTER_ERROR } from 'ee/security_dashboard/components/shared/filters/constants';
import { imageFilter } from 'ee/security_dashboard/helpers';
import agentImagesQuery from 'ee/security_dashboard/graphql/queries/agent_images.query.graphql';
import projectImagesQuery from 'ee/security_dashboard/graphql/queries/project_images.query.graphql';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { agentVulnerabilityImages, projectVulnerabilityImages } from '../../mock_data';

jest.mock('~/flash');

describe('Image Filter component', () => {
  let wrapper;
  const projectFullPath = 'test/path';
  const defaultQueryResolver = {
    agent: jest.fn().mockResolvedValue(agentVulnerabilityImages),
    project: jest.fn().mockResolvedValue(projectVulnerabilityImages),
  };
  const mockImages = projectVulnerabilityImages.data.project.vulnerabilityImages.nodes;

  const createMockApolloProvider = ({
    agentQueryResolver = defaultQueryResolver.agent,
    projectQueryResolver = defaultQueryResolver.project,
  }) => {
    Vue.use(VueApollo);
    return createMockApollo([
      [agentImagesQuery, agentQueryResolver],
      [projectImagesQuery, projectQueryResolver],
    ]);
  };

  const createWrapper = ({ agentQueryResolver, projectQueryResolver, provide = {} } = {}) => {
    wrapper = shallowMount(ImageFilter, {
      apolloProvider: createMockApolloProvider({ agentQueryResolver, projectQueryResolver }),
      propsData: { filter: imageFilter },
      provide: { projectFullPath, ...provide },
      directives: { GlTooltip: createMockDirective() },
    });
  };

  const findFilterItems = () => wrapper.findAllComponents(FilterItem);

  const expectFilterItem = (item, name) => {
    const tooltip = getBinding(item.element, 'gl-tooltip');
    const truncate = item.findComponent(GlTruncate);

    expect(item.props('isChecked')).toBe(false);

    expect(truncate.attributes('title')).toBe('');
    expect(truncate.props()).toMatchObject({ text: name, position: 'middle' });

    expect(tooltip.modifiers).toStrictEqual({ left: true, viewport: true });
    expect(tooltip.value).toBe(name);
  };

  afterEach(() => {
    createAlert.mockClear();
    wrapper.destroy();
  });

  describe('project page', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('retrieves the options for the project page', () => {
      expect(defaultQueryResolver.agent).not.toHaveBeenCalled();
      expect(defaultQueryResolver.project).toHaveBeenCalledTimes(1);
      expect(defaultQueryResolver.project.mock.calls[0][0]).toEqual({
        agentName: '',
        projectPath: projectFullPath,
      });
    });

    it('displays the all option item', () => {
      expect(findFilterItems().at(0).props()).toStrictEqual({
        isChecked: true,
        text: 'All images',
      });
    });

    it('populates the filter options from the query response', () => {
      mockImages.forEach(({ name }, index) => {
        expectFilterItem(findFilterItems().at(index + 1), name);
      });
    });
  });

  describe('agent page', () => {
    const agentName = 'test-agent-name';
    beforeEach(async () => {
      createWrapper({ provide: { agentName } });
      await waitForPromises();
    });

    it('retrieves the options for the agent page', () => {
      expect(defaultQueryResolver.project).not.toHaveBeenCalled();
      expect(defaultQueryResolver.agent).toHaveBeenCalledTimes(1);
      expect(defaultQueryResolver.agent.mock.calls[0][0]).toEqual({
        agentName,
        projectPath: projectFullPath,
      });
    });

    it('populates the filter options from the query response', () => {
      mockImages.forEach(({ name }, index) => {
        expectFilterItem(findFilterItems().at(index + 1), name);
      });
    });
  });

  it('shows an alert on a failed graphql request', async () => {
    const errorSpy = jest.fn().mockRejectedValue();
    createWrapper({ projectQueryResolver: errorSpy });
    await waitForPromises();
    expect(createAlert).toHaveBeenCalledWith({ message: IMAGE_FILTER_ERROR });
  });
});
