import { GlCollapsibleListbox, GlTruncate } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import ImageFilter from 'ee/security_dashboard/components/shared/filters/image_filter.vue';
import QuerystringSync from 'ee/security_dashboard/components/shared/filters/querystring_sync.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { ALL_ID } from 'ee/security_dashboard/components/shared/filters/constants';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import agentImagesQuery from 'ee/security_dashboard/graphql/queries/agent_images.query.graphql';
import projectImagesQuery from 'ee/security_dashboard/graphql/queries/project_images.query.graphql';
import { createMockDirective } from 'helpers/vue_mock_directive';
import { agentVulnerabilityImages, projectVulnerabilityImages } from '../../mock_data';

jest.mock('~/alert');
Vue.use(VueApollo);

describe('ImageFilter component', () => {
  let wrapper;
  const projectFullPath = 'test/path';
  const defaultQueryResolver = {
    agent: jest.fn().mockResolvedValue(agentVulnerabilityImages),
    project: jest.fn().mockResolvedValue(projectVulnerabilityImages),
  };
  const mockImages = projectVulnerabilityImages.data.project.vulnerabilityImages.nodes.map(
    ({ name }) => name,
  );

  const createWrapper = ({
    agentQueryResolver = defaultQueryResolver.agent,
    projectQueryResolver = defaultQueryResolver.project,
    provide = {},
  } = {}) => {
    wrapper = mountExtended(ImageFilter, {
      apolloProvider: createMockApollo([
        [agentImagesQuery, agentQueryResolver],
        [projectImagesQuery, projectQueryResolver],
      ]),
      provide: { projectFullPath, ...provide },
      directives: { GlTooltip: createMockDirective('gl-tooltip') },
      stubs: { QuerystringSync: true },
    });
  };

  const findQuerystringSync = () => wrapper.findComponent(QuerystringSync);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxItem = (name) => wrapper.findByTestId(`listbox-item-${name}`);

  const clickListboxItem = (name) => {
    return findListboxItem(name).trigger('click');
  };

  const expectSelectedItems = (ids) => {
    expect(findListbox().props('selected')).toEqual(ids);
  };

  const expectListboxItem = (value, name) => {
    const item = findListboxItem(value);
    const truncate = item.findComponent(GlTruncate);

    expect(truncate.props()).toMatchObject({ text: name, position: 'middle' });
  };

  describe('basic structure', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    describe('QuerystringSync component', () => {
      it('has expected props', () => {
        expect(findQuerystringSync().props()).toMatchObject({
          querystringKey: 'image',
          value: [],
        });
      });

      it.each`
        emitted            | expected
        ${[]}              | ${[ALL_ID]}
        ${[mockImages[0]]} | ${[mockImages[0]]}
      `('restores selected items - $emitted', async ({ emitted, expected }) => {
        await findQuerystringSync().vm.$emit('input', emitted);

        expectSelectedItems(expected);
      });
    });

    describe('default view', () => {
      it('shows the label', () => {
        expect(wrapper.find('label').text()).toBe(ImageFilter.i18n.label);
      });

      it('shows the dropdown with correct header text', () => {
        expect(findListbox().props('headerText')).toBe(ImageFilter.i18n.label);
      });

      it('passes the placeholder toggle text when no items are selected', () => {
        expect(findListbox().props('toggleText')).toBe(ImageFilter.i18n.allItemsText);
      });

      it(`passes '${mockImages[0]}' when only ${mockImages[0]} is selected`, async () => {
        await clickListboxItem(mockImages[0]);

        expect(findListbox().props('toggleText')).toBe(mockImages[0]);
      });

      it(`passes '${mockImages[0]} +1 more' when ${mockImages[0]} and another image is selected`, async () => {
        await clickListboxItem(mockImages[0]);
        await clickListboxItem(mockImages[1]);

        expect(findListbox().props('toggleText')).toBe(`${mockImages[0]} +1 more`);
      });
    });

    describe('filter-changed event', () => {
      it('emits filter-changed event when selected item is changed', async () => {
        const images = [];
        await clickListboxItem(ALL_ID);

        expect(wrapper.emitted('filter-changed')[0][0].image).toEqual([]);

        for await (const image of mockImages) {
          await clickListboxItem(image);
          images.push(image);

          expect(wrapper.emitted('filter-changed')[images.length][0].image).toEqual(images);
        }
      });
    });

    describe('dropdown items', () => {
      it('populates all dropdown items with correct text', () => {
        expect(findListbox().props('items')).toHaveLength(mockImages.length + 1);
        expectListboxItem(ALL_ID, ImageFilter.i18n.allItemsText);
        mockImages.forEach((image) => expectListboxItem(image, image));
      });

      it('allows multiple items to be selected', async () => {
        const images = [];

        for await (const image of mockImages) {
          await clickListboxItem(image);
          images.push(image);

          expectSelectedItems(images);
        }
      });

      it('toggles the item selection when clicked on', async () => {
        for await (const image of mockImages) {
          await clickListboxItem(image);

          expectSelectedItems([image]);

          await clickListboxItem(image);

          expectSelectedItems([ALL_ID]);
        }
      });

      it('selects ALL item when created', () => {
        expectSelectedItems([ALL_ID]);
      });

      it('selects ALL item and deselects everything else when it is clicked', async () => {
        await clickListboxItem(ALL_ID);
        await clickListboxItem(ALL_ID); // Click again to verify that it doesn't toggle.

        expectSelectedItems([ALL_ID]);
      });

      it('deselects the ALL item when another item is clicked', async () => {
        await clickListboxItem(ALL_ID);
        await clickListboxItem(mockImages[0]);

        expectSelectedItems([mockImages[0]]);
      });
    });
  });

  describe('agent page', () => {
    const agentName = 'test-agent-name';

    const agentMockImages = agentVulnerabilityImages.data.project.clusterAgent.vulnerabilityImages.nodes.map(
      ({ name }) => name,
    );

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

    it('populates all dropdown items with correct text', () => {
      expect(findListbox().props('items')).toHaveLength(agentMockImages.length + 1);
      expectListboxItem(ALL_ID, ImageFilter.i18n.allItemsText);
      agentMockImages.forEach((image) => expectListboxItem(image, image));
    });
  });

  it('shows an alert on a failed GraphQL request', async () => {
    createWrapper({ projectQueryResolver: jest.fn().mockRejectedValue() });
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({ message: ImageFilter.i18n.loadingError });
  });
});
