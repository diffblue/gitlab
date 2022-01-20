import { GlFormInput, GlModal } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import merge from 'lodash/merge';
import Vuex from 'vuex';
import MetricsImage from 'ee/issues/show/components/incidents/metrics_image.vue';
import MetricsTab from 'ee/issues/show/components/incidents/metrics_tab.vue';
import { getMetricImages } from 'ee/issues/show/components/incidents/service';
import createStore from 'ee/issues/show/components/incidents/store';
import waitForPromises from 'helpers/wait_for_promises';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import { fileList, initialData } from './mock_data';

jest.mock('ee/issues/show/components/incidents/service', () => ({
  getMetricImages: jest.fn(),
}));

const mockEvent = { preventDefault: jest.fn() };

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Metrics tab', () => {
  let wrapper;
  let store;

  const mountComponent = (options = {}) => {
    store = createStore();

    wrapper = shallowMount(
      MetricsTab,
      merge(
        {
          localVue,
          store,
          provide: {
            canUpdate: true,
            iid: initialData.issueIid,
            projectId: initialData.projectId,
          },
        },
        options,
      ),
    );
  };

  beforeEach(() => {
    mountComponent();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findUploadDropzone = () => wrapper.findComponent(UploadDropzone);
  const findImages = () => wrapper.findAllComponents(MetricsImage);
  const findModal = () => wrapper.findComponent(GlModal);
  const submitModal = () => findModal().vm.$emit('primary', mockEvent);
  const cancelModal = () => findModal().vm.$emit('hidden');

  describe('empty state', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders the upload component', () => {
      expect(findUploadDropzone().exists()).toBe(true);
    });
  });

  describe('permissions', () => {
    beforeEach(() => {
      mountComponent({ provide: { canUpdate: false } });
    });

    it('hides the upload component when disallowed', () => {
      expect(findUploadDropzone().exists()).toBe(false);
    });
  });

  describe('onLoad action', () => {
    it('should load images', async () => {
      getMetricImages.mockImplementation(() => Promise.resolve(fileList));

      mountComponent();

      await waitForPromises();

      expect(findImages().length).toBe(1);
    });
  });

  describe('add metric dialog', () => {
    const testUrl = 'test url';

    it('should open the add metric dialog when clicked', async () => {
      mountComponent();

      findUploadDropzone().vm.$emit('change');

      await waitForPromises();

      expect(findModal().attributes('visible')).toBe('true');
    });

    it('should close when cancelled', async () => {
      mountComponent({
        data() {
          return { modalVisible: true };
        },
      });

      cancelModal();

      await waitForPromises();

      expect(findModal().attributes('visible')).toBeFalsy();
    });

    it('should add files and url when selected', async () => {
      mountComponent({
        data() {
          return { modalVisible: true, modalUrl: testUrl, currentFiles: fileList };
        },
      });

      const dispatchSpy = jest.spyOn(store, 'dispatch');

      submitModal();

      await waitForPromises();

      expect(dispatchSpy).toHaveBeenCalledWith('uploadImage', { files: fileList, url: testUrl });
    });

    describe('url field', () => {
      beforeEach(() => {
        mountComponent({
          data() {
            return { modalVisible: true, modalUrl: testUrl };
          },
        });
      });

      it('should display the url field', () => {
        expect(wrapper.findComponent(GlFormInput).attributes('value')).toBe(testUrl);
      });

      it('should clear url when cancelled', async () => {
        cancelModal();

        await waitForPromises();

        expect(wrapper.findComponent(GlFormInput).attributes('value')).toBe('');
      });

      it('should clear url when submitted', async () => {
        submitModal();

        await waitForPromises();

        expect(wrapper.findComponent(GlFormInput).attributes('value')).toBe('');
      });
    });
  });
});
