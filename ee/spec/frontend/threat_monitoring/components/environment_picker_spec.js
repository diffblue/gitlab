import { GlButton, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EnvironmentPicker from 'ee/threat_monitoring/components/environment_picker.vue';
import {
  INVALID_CURRENT_ENVIRONMENT_NAME,
  LOADING_TEXT,
  ALL_ENVIRONMENT_NAME,
} from 'ee/threat_monitoring/constants';
import createStore from 'ee/threat_monitoring/store';
import { mockEnvironmentsResponse } from '../mocks/mock_data';

const mockEnvironments = mockEnvironmentsResponse.environments;
const currentEnvironment = mockEnvironments[1];

describe('EnvironmentPicker component', () => {
  let store;
  let wrapper;
  let fetchEnvironmentsSpy;

  const factory = (state = {}, propsData = {}) => {
    store = createStore();
    store.replaceState({
      ...store.state,
      threatMonitoring: {
        ...store.state.threatMonitoring,
        currentEnvironmentId: currentEnvironment.id,
        environments: mockEnvironments,
        hasEnvironment: true,
        nextPage: 'someHash',
        ...state,
      },
    });

    fetchEnvironmentsSpy = jest
      .spyOn(EnvironmentPicker.methods, 'fetchEnvironments')
      .mockImplementation(() => {});

    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMount(EnvironmentPicker, {
      propsData,
      store,
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findLoadMoreButton = () => wrapper.findComponent(GlButton);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when there are environments', () => {
    beforeEach(() => {
      factory();
    });

    it('fetches the environments when created', async () => {
      expect(fetchEnvironmentsSpy).toHaveBeenCalled();
    });

    it('is not disabled', () => {
      expect(findDropdown().attributes().disabled).toBe(undefined);
    });

    it('has text set to the current environment', () => {
      expect(findDropdown().attributes().text).toBe(currentEnvironment.name);
    });

    it('has dropdown items for each environment', () => {
      const dropdownItems = findDropdownItems();
      mockEnvironments.forEach((environment, i) => {
        const dropdownItem = dropdownItems.at(i);
        expect(dropdownItem.text()).toBe(environment.name);
        dropdownItem.vm.$emit('click');
        expect(store.dispatch).toHaveBeenCalledWith(
          'threatMonitoring/setCurrentEnvironmentId',
          environment.id,
        );
      });
    });

    it('shows the "Load more" button when there are more environments to fetch', () => {
      expect(findLoadMoreButton().exists()).toBe(true);
    });
  });

  describe('when there are no environments', () => {
    beforeEach(() => {
      factory({
        environments: [],
        hasEnvironment: false,
        isLoadingEnvironments: false,
        nextPage: '',
      });
    });

    it('disables the environments dropdown', () => {
      expect(findDropdown().attributes()).toMatchObject({
        disabled: 'true',
        text: INVALID_CURRENT_ENVIRONMENT_NAME,
      });
    });

    it('has no dropdown items', () => {
      expect(findDropdownItems()).toHaveLength(0);
    });

    it('does not fetch the environments when created', () => {
      expect(fetchEnvironmentsSpy).not.toHaveBeenCalled();
    });

    it('does not show the "Load more" button', () => {
      expect(findLoadMoreButton().exists()).toBe(false);
    });
  });

  describe('when includeAll is enabled', () => {
    beforeEach(() => {
      factory({ allEnvironments: true }, { includeAll: true });
    });

    it('has text set to the all environment option', () => {
      expect(findDropdown().attributes().text).toBe(ALL_ENVIRONMENT_NAME);
    });
  });

  describe('when environments are loading', () => {
    beforeEach(() => {
      factory({ environments: [], isLoadingEnvironments: true });
    });

    it('disables the environments dropdown', () => {
      expect(findDropdown().attributes()).toMatchObject({
        disabled: 'true',
        text: LOADING_TEXT,
        loading: 'true',
      });
    });
  });
});
