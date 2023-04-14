import { GlAlert, GlDropdown, GlDropdownItem, GlEmptyState, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import { INSIGHTS_CONFIGURATION_TEXT } from 'ee/insights/constants';
import Insights from 'ee/insights/components/insights.vue';
import { createStore } from 'ee/insights/stores';
import { pageInfo } from 'ee_jest/insights/mock_data';
import { TEST_HOST } from 'helpers/test_constants';

Vue.use(Vuex);
const defaultMocks = {
  $route: {
    params: {},
  },
  $router: {
    replace() {},
    push() {},
  },
};

const defaultKey = 'issues';
const selectedKey = 'mrs';
const selectedKeyMocks = {
  $route: {
    params: {
      tabId: selectedKey,
    },
  },
};

const invalidKeyMocks = {
  $route: {
    params: {
      tabId: 'invalid',
    },
  },
};

const createComponent = (store, options = {}) => {
  const { mocks = defaultMocks } = options;
  return shallowMount(Insights, {
    store,
    propsData: {
      endpoint: TEST_HOST,
      queryEndpoint: `${TEST_HOST}/query`,
    },
    stubs: ['router-link', 'router-view'],
    mocks,
  });
};

describe('Insights component', () => {
  let mock;
  let wrapper;
  let vuexStore;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    vuexStore = createStore();
    jest.spyOn(vuexStore, 'dispatch').mockImplementation(() => {});
    wrapper = createComponent(vuexStore);
  });

  afterEach(() => {
    mock.restore();
    vuexStore.dispatch.mockReset();
  });

  it('fetches config data when mounted', () => {
    expect(vuexStore.dispatch).toHaveBeenCalledWith('insights/fetchConfigData', TEST_HOST);
  });

  it('renders insights configuration text', () => {
    const text = wrapper.findComponent(GlSprintf).attributes('message');

    expect(text).toBe(INSIGHTS_CONFIGURATION_TEXT);
  });

  describe('when loading config', () => {
    it('renders config loading state', () => {
      vuexStore.state.insights.configLoading = true;

      expect(wrapper.find('.insights-config-loading').exists()).toBe(true);
      expect(wrapper.find('.insights-wrapper').exists()).toBe(false);
    });
  });

  describe('when config loaded', () => {
    const title = 'Bugs Per Team';
    const chart1 = { title: 'foo' };
    const chart2 = { title: 'bar' };

    describe('when no charts have been requested', () => {
      const page = {
        title,
        charts: [],
      };

      beforeEach(() => {
        vuexStore.state.insights.configLoading = false;
        vuexStore.state.insights.activePage = page;
        vuexStore.state.insights.configData = {
          bugsPerTeam: page,
        };
      });

      it('has the correct nav tabs', async () => {
        await nextTick();
        expect(wrapper.findComponent(GlDropdown).exists()).toBe(true);
        expect(wrapper.findComponent(GlDropdown).findComponent(GlDropdownItem).text()).toBe(title);
      });

      it('should not disable the tab selector', async () => {
        await nextTick();
        expect(wrapper.findComponent(GlDropdown).attributes().disabled).toBeUndefined();
      });
    });

    describe('when charts have not been initialized', () => {
      const page = {
        title,
        charts: [chart1, chart2],
      };

      beforeEach(() => {
        vuexStore.state.insights.configLoading = false;
        vuexStore.state.insights.activePage = page;
        vuexStore.state.insights.configData = {
          bugsPerTeam: page,
        };
      });

      it('has the correct nav tabs', async () => {
        await nextTick();
        expect(wrapper.findComponent(GlDropdown).exists()).toBe(true);
        expect(wrapper.findComponent(GlDropdown).findComponent(GlDropdownItem).text()).toBe(title);
      });

      it('disables the tab selector', async () => {
        await nextTick();
        expect(wrapper.findComponent(GlDropdown).attributes()).toMatchObject({ disabled: 'true' });
      });
    });

    describe('when charts have been initialized', () => {
      const page = {
        title,
        charts: [chart1, chart2],
      };

      beforeEach(() => {
        vuexStore.state.insights.configLoading = false;
        vuexStore.state.insights.activePage = page;
        vuexStore.state.insights.configData = {
          bugsPerTeam: page,
        };
        vuexStore.state.insights.chartData = {
          [chart1.title]: {},
          [chart2.title]: {},
        };
      });

      it('enables the tab selector', async () => {
        await nextTick();
        expect(wrapper.findComponent(GlDropdown).attributes()).toMatchObject({ disabled: 'true' });
      });
    });

    describe('when some charts have been loaded', () => {
      const page = {
        title,
        charts: [chart1],
      };

      beforeEach(() => {
        vuexStore.state.insights.configLoading = false;
        vuexStore.state.insights.activePage = page;
        vuexStore.state.insights.configData = {
          bugsPerTeam: page,
        };
        vuexStore.state.insights.chartData = {
          [chart2.title]: { loaded: true },
        };
      });

      it('disables the tab selector', async () => {
        await nextTick();
        expect(wrapper.findComponent(GlDropdown).attributes()).toMatchObject({ disabled: 'true' });
      });
    });

    describe('when all charts have loaded', () => {
      const page = {
        title,
        charts: [chart1, chart2],
      };

      beforeEach(() => {
        vuexStore.state.insights.configLoading = false;
        vuexStore.state.insights.activePage = page;
        vuexStore.state.insights.configData = {
          bugsPerTeam: page,
        };
        vuexStore.state.insights.chartData = {
          [chart1.title]: { loaded: true },
          [chart2.title]: { loaded: true },
        };
      });

      it('enables the tab selector', async () => {
        await nextTick();
        expect(wrapper.findComponent(GlDropdown).attributes().disabled).toBeUndefined();
      });
    });

    describe('when one chart has an error', () => {
      const page = {
        title,
        charts: [chart1, chart2],
      };

      beforeEach(() => {
        vuexStore.state.insights.configLoading = false;
        vuexStore.state.insights.activePage = page;
        vuexStore.state.insights.configData = {
          bugsPerTeam: page,
        };
        vuexStore.state.insights.chartData = {
          [chart1.title]: { error: 'Baz' },
          [chart2.title]: { loaded: true },
        };
      });

      it('enables the tab selector', async () => {
        await nextTick();
        expect(wrapper.findComponent(GlDropdown).attributes().disabled).toBeUndefined();
      });
    });
  });

  describe('empty config', () => {
    beforeEach(() => {
      vuexStore.state.insights.configLoading = false;
      vuexStore.state.insights.configData = null;
    });

    it('displays a warning', async () => {
      await nextTick();
      expect(wrapper.findComponent(GlEmptyState).attributes()).toMatchObject({
        title: 'Invalid Insights config file detected',
      });
    });

    it('does not display dropdown', async () => {
      await nextTick();
      expect(wrapper.findComponent(GlDropdown).exists()).toBe(false);
    });
  });

  describe('filtered out items', () => {
    beforeEach(() => {
      vuexStore.state.insights.configLoading = false;
      vuexStore.state.insights.configData = {};
    });

    it('displays a warning', async () => {
      await nextTick();
      expect(wrapper.findComponent(GlAlert).text()).toContain(
        'This project is filtered out in the insights.yml file',
      );
    });

    it('does not display dropdown', async () => {
      await nextTick();
      expect(wrapper.findComponent(GlDropdown).exists()).toBe(false);
    });
  });

  describe('hash fragment present', () => {
    const configData = {};
    configData[defaultKey] = {};
    configData[selectedKey] = {};

    beforeEach(() => {
      vuexStore.state.insights.configLoading = false;
      vuexStore.state.insights.configData = configData;
      vuexStore.state.insights.activePage = pageInfo;
    });

    it('selects the first tab if invalid', async () => {
      wrapper = createComponent(vuexStore, { mocks: { ...defaultMocks, ...invalidKeyMocks } });

      jest.runOnlyPendingTimers();

      await nextTick();
      expect(vuexStore.dispatch).toHaveBeenCalledWith('insights/setActiveTab', defaultKey);
    });

    it('selects the specified tab if valid', async () => {
      wrapper = createComponent(vuexStore, { mocks: { ...defaultMocks, ...selectedKeyMocks } });

      jest.runOnlyPendingTimers();

      await nextTick();
      expect(vuexStore.dispatch).toHaveBeenCalledWith('insights/setActiveTab', selectedKey);
    });
  });

  describe('dropdown title', () => {
    const configData = {};
    configData[defaultKey] = { title: 'Default key title' };
    configData[selectedKey] = { title: 'Selected key title' };

    beforeEach(() => {
      vuexStore.state.insights.configLoading = false;
      vuexStore.state.insights.configData = configData;
      vuexStore.state.insights.activePage = pageInfo;
    });

    it('uses the default title when there is no active tab specified', async () => {
      wrapper = createComponent(vuexStore, { mocks: { ...defaultMocks, ...selectedKeyMocks } });

      jest.runOnlyPendingTimers();

      await nextTick();
      expect(wrapper.findComponent(GlDropdown).attributes('text')).toBe('Select report');
    });

    it('sets the title when there is an active tab specified', async () => {
      vuexStore.state.insights.activeTab = selectedKey;

      wrapper = createComponent(vuexStore, { mocks: { ...defaultMocks, ...selectedKeyMocks } });

      jest.runOnlyPendingTimers();

      await nextTick();
      expect(wrapper.findComponent(GlDropdown).attributes('text')).toBe('Selected key title');
    });
  });
});
