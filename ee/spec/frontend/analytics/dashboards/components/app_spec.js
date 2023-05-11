import { GlLink, GlSkeletonLoader, GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  DASHBOARD_TITLE,
  DASHBOARD_DESCRIPTION,
  DASHBOARD_DOCS_LINK,
} from 'ee/analytics/dashboards/constants';
import * as utils from 'ee/analytics/dashboards/utils';
import Component from 'ee/analytics/dashboards/components/app.vue';
import DoraVisualization from 'ee/analytics/dashboards/components/dora_visualization.vue';

describe('Executive dashboard app', () => {
  let wrapper;
  const fullPath = 'groupFullPath';
  const tooManyPaths = ['group', 'group/a', 'group/b', 'group/c', 'group/d', 'group/e'];
  const tooManyWidgets = tooManyPaths.map((namespace) => ({ data: { namespace } }));

  const createWrapper = async ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(Component, {
      propsData: {
        fullPath,
        ...props,
      },
    });

    await waitForPromises();
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findTitle = () => wrapper.findByTestId('dashboard-title');
  const findDescription = () => wrapper.findByTestId('dashboard-description');
  const findDoraVisualizations = () => wrapper.findAllComponents(DoraVisualization);

  it('shows a loading skeleton when fetching the YAML config', () => {
    createWrapper();
    expect(findSkeletonLoader().exists()).toBe(true);
  });

  describe('default config', () => {
    it('renders the page title', async () => {
      await createWrapper();
      expect(findTitle().text()).toBe(DASHBOARD_TITLE);
    });

    it('renders the description', async () => {
      await createWrapper();
      expect(findDescription().text()).toContain(DASHBOARD_DESCRIPTION);
      expect(findDescription().findComponent(GlLink).attributes('href')).toBe(DASHBOARD_DOCS_LINK);
    });

    it('renders a visualization for the group fullPath', async () => {
      await createWrapper();
      const charts = findDoraVisualizations();
      expect(charts.length).toBe(1);

      const [chart] = charts.wrappers;
      expect(chart.props()).toMatchObject({ data: { namespace: fullPath } });
    });

    it('does not render more than 4 visualizations', async () => {
      await createWrapper({ props: { queryPaths: tooManyPaths } });
      const charts = findDoraVisualizations();
      expect(charts.length).toBe(4);
    });

    it('queryPaths are shown in addition to the group visualization', async () => {
      const queryPaths = ['group/one', 'group/two', 'group/three'];
      await createWrapper({ props: { queryPaths } });

      const charts = findDoraVisualizations();
      expect(charts.length).toBe(4);

      [fullPath, ...queryPaths].forEach((namespace, index) => {
        expect(charts.wrappers[index].props()).toMatchObject({ data: { namespace } });
      });
    });
  });

  describe('YAML config', () => {
    const yamlConfigProject = { id: 3, fullPath: 'group/project' };
    const widgets = [
      { title: 'One', data: { namespace: 'group/one' } },
      { data: { namespace: 'group/two' } },
    ];

    it('falls back to the default config with an alert if it fails to fetch', async () => {
      jest.spyOn(utils, 'fetchYamlConfig').mockResolvedValue(null);
      await createWrapper({ props: { yamlConfigProject } });
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe('Failed to load YAML config from Project: group/project');
    });

    it('renders a custom page title', async () => {
      const title = 'TEST TITLE';
      jest.spyOn(utils, 'fetchYamlConfig').mockResolvedValue({ title });
      await createWrapper({ props: { yamlConfigProject } });
      expect(findTitle().text()).toBe(title);
    });

    it('renders a custom description', async () => {
      const description = 'TEST DESCRIPTION';
      jest.spyOn(utils, 'fetchYamlConfig').mockResolvedValue({ description });
      await createWrapper({ props: { yamlConfigProject } });
      expect(findDescription().text()).toBe(description);
      expect(findDescription().findComponent(GlLink).exists()).toBe(false);
    });

    it('renders a visualization for each widget', async () => {
      jest.spyOn(utils, 'fetchYamlConfig').mockResolvedValue({ widgets });
      await createWrapper({ props: { yamlConfigProject } });

      const charts = findDoraVisualizations();
      expect(charts.length).toBe(2);

      expect(charts.wrappers[0].props()).toMatchObject(widgets[0]);
      expect(charts.wrappers[1].props()).toMatchObject(widgets[1]);
    });

    it('does not render more than 4 visualizations', async () => {
      jest.spyOn(utils, 'fetchYamlConfig').mockResolvedValue({ widgets: tooManyWidgets });
      await createWrapper({ props: { yamlConfigProject } });

      const charts = findDoraVisualizations();
      expect(charts.length).toBe(4);
    });

    it('queryPaths override the widgets list', async () => {
      const queryPaths = ['group/one', 'group/two', 'group/three'];

      jest.spyOn(utils, 'fetchYamlConfig').mockResolvedValue({ widgets });
      await createWrapper({ props: { yamlConfigProject, queryPaths } });

      const charts = findDoraVisualizations();
      expect(charts.length).toBe(4);

      [fullPath, ...queryPaths].forEach((namespace, index) => {
        expect(charts.wrappers[index].props()).toMatchObject({ data: { namespace } });
      });
    });
  });
});
