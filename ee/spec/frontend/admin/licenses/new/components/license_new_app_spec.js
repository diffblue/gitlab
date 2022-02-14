import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import LicenseNewApp from 'ee/admin/licenses/new/components/license_new_app.vue';
import { FILE_UPLOAD_ERROR_MESSAGE } from 'ee/admin/licenses/new/constants';
import createFlash from '~/flash';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';

jest.mock('~/flash');

describe('Upload dropzone component', () => {
  let wrapper;

  const findUploadDropzone = () => wrapper.find(UploadDropzone);

  function createComponent() {
    wrapper = shallowMount(LicenseNewApp, {
      stubs: {
        GlSprintf,
      },
    });
  }

  beforeEach(() => {
    createFlash.mockClear();
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('displays an error when upload-dropzone emits an error', async () => {
    findUploadDropzone().vm.$emit('error');

    await nextTick();
    expect(createFlash).toHaveBeenCalledWith({ message: FILE_UPLOAD_ERROR_MESSAGE });
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
