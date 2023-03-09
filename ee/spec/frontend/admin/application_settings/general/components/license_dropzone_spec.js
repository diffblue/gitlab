import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import LicenseDropzone from 'ee/admin/application_settings/general/components/license_dropzone.vue';
import { FILE_UPLOAD_ERROR_MESSAGE } from 'ee/admin/application_settings/general/constants';
import { createAlert } from '~/alert';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';

jest.mock('~/alert');

describe('Upload dropzone component', () => {
  let wrapper;

  const findUploadDropzone = () => wrapper.findComponent(UploadDropzone);

  function createComponent() {
    wrapper = shallowMount(LicenseDropzone, {
      stubs: {
        GlSprintf,
      },
    });
  }

  beforeEach(() => {
    createAlert.mockClear();
    createComponent();
  });

  it('displays an error when upload-dropzone emits an error', async () => {
    findUploadDropzone().vm.$emit('error');

    await nextTick();
    expect(createAlert).toHaveBeenCalledWith({ message: FILE_UPLOAD_ERROR_MESSAGE });
  });

  it('displays filename when the file is set in upload-dropzone', async () => {
    const uploadDropzone = findUploadDropzone();
    uploadDropzone.vm.$emit('change', { name: 'test-license.txt' });

    await nextTick();
    expect(wrapper.text()).toEqual(expect.stringContaining('test-license.txt'));
  });

  it('properly resets filename when the file was unset by the upload-dropzone', async () => {
    const uploadDropzone = findUploadDropzone();
    uploadDropzone.vm.$emit('change', { name: 'test-license.txt' });
    await nextTick();

    uploadDropzone.vm.$emit('change', null);
    await nextTick();

    expect(wrapper.text()).not.toEqual(expect.stringContaining('test-license.txt'));
  });

  describe('allows only license file types for the dropzone', () => {
    const properLicenseFileExtensions = ['.gitlab_license', '.gitlab-license', '.txt'];
    let isFileValid;
    let validFileMimetypes;

    beforeEach(() => {
      createComponent();
      const uploadDropzone = findUploadDropzone();
      isFileValid = uploadDropzone.props('isFileValid');
      validFileMimetypes = uploadDropzone.props('validFileMimetypes');
    });

    it('should pass proper extension list for file picker dialogue', () => {
      expect(validFileMimetypes).toEqual(properLicenseFileExtensions);
    });

    it.each(properLicenseFileExtensions)('allows %s file extension', (extension) => {
      expect(isFileValid({ name: `license${extension}` })).toBe(true);
    });

    it.each(['.pdf', '.jpg', '.html'])('rejects %s file extension', (extension) => {
      expect(isFileValid({ name: `license${extension}` })).toBe(false);
    });
  });
});
