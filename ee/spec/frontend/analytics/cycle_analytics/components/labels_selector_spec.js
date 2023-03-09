import { GlDropdownSectionHeader } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import LabelsSelector from 'ee/analytics/cycle_analytics/components/labels_selector.vue';
import createStore from 'ee/analytics/cycle_analytics/store';
import * as getters from 'ee/analytics/cycle_analytics/store/getters';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { groupLabels } from '../mock_data';

jest.mock('~/alert');
Vue.use(Vuex);

const selectedLabel = groupLabels[groupLabels.length - 1];

const findCheckedItem = (wrapper) =>
  wrapper
    .findAll('gl-dropdown-item-stub')
    .filter((d) => d.attributes('active'))
    .at(0);

const mockGroupLabelsRequest = (status = HTTP_STATUS_OK) =>
  new MockAdapter(axios).onGet().reply(status, groupLabels);

describe('Value Stream Analytics LabelsSelector', () => {
  let store = null;

  function createComponent({
    props = { selectedLabelNames: [] },
    shallow = true,
    state = {},
  } = {}) {
    store = createStore();
    const func = shallow ? shallowMount : mount;
    return func(LabelsSelector, {
      store: {
        ...store,
        state: {
          defaultGroupLabels: groupLabels,
          ...state,
        },
        getters: {
          ...getters,
          currentGroupPath: 'fake',
        },
      },
      propsData: {
        ...props,
      },
    });
  }

  let wrapper = null;
  let mock = null;
  const labelNames = groupLabels.map(({ name }) => name);

  describe('with no item selected', () => {
    beforeEach(() => {
      mock = mockGroupLabelsRequest();
      wrapper = createComponent({});

      return waitForPromises();
    });

    afterEach(() => {
      mock.restore();
    });

    it('will render the label selector', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });

    it.each(labelNames)('generate a label item for the label %s', (name) => {
      expect(wrapper.text()).toContain(name);
    });

    it('will render with the default option selected', () => {
      const sectionHeader = wrapper.findComponent(GlDropdownSectionHeader);

      expect(sectionHeader.exists()).toBe(true);
      expect(sectionHeader.text()).toEqual('Select a label');
    });

    describe('with a failed request', () => {
      beforeEach(() => {
        mock = mockGroupLabelsRequest(HTTP_STATUS_NOT_FOUND);
        wrapper = createComponent({ state: { defaultGroupLabels: [] } });

        return waitForPromises();
      });

      it('should alert an error message', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'There was an error fetching label data for the selected group',
        });
      });
    });

    describe('when a dropdown item is clicked', () => {
      beforeEach(() => {
        mock = mockGroupLabelsRequest();
        wrapper = createComponent({ shallow: false });
        return waitForPromises();
      });

      it('will emit the "select-label" event', async () => {
        expect(wrapper.emitted('select-label')).toBeUndefined();

        const elem = wrapper.findAll('.dropdown-item').at(1);
        elem.trigger('click');

        await nextTick();
        expect(wrapper.emitted('select-label').length > 0).toBe(true);
        expect(wrapper.emitted('select-label')[0]).toContain(groupLabels[1]);
      });
    });
  });

  describe('with no default labels', () => {
    beforeEach(() => {
      mock = mockGroupLabelsRequest();
      wrapper = createComponent({ state: { defaultGroupLabels: [] } });

      return waitForPromises();
    });

    it('will fetch the labels', () => {
      expect(mock.history.get.length).toBe(1);
    });
  });

  describe('with selectedLabelNames set', () => {
    beforeEach(() => {
      mock = mockGroupLabelsRequest();
      wrapper = createComponent({ props: { selectedLabelNames: [selectedLabel.title] } });
      return waitForPromises();
    });

    it('will render the label selector', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });

    it('will set the active label', () => {
      const activeItem = findCheckedItem(wrapper);

      expect(activeItem.exists()).toBe(true);
      expect(activeItem.text()).toEqual(selectedLabel.name);
    });
  });

  describe('with labels provided', () => {
    beforeEach(() => {
      mock = mockGroupLabelsRequest();
      wrapper = createComponent({ props: { initialData: groupLabels } });
    });

    it('will not fetch the labels', () => {
      expect(mock.history.get.length).toBe(0);
    });
  });
});
