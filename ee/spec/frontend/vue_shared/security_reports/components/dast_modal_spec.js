import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Component from 'ee/vue_shared/security_reports/components/dast_modal.vue';

describe('DAST Modal', () => {
  let wrapper;

  const defaultProps = {
    scannedUrls: [{ requestMethod: 'POST', url: 'https://gitlab.com' }],
    scannedResourcesCount: 1,
    downloadLink: 'https://gitlab.com',
  };

  const findDownloadLink = () => wrapper.find('[data-testid="download-link"]');

  const createWrapper = (propsData) => {
    wrapper = shallowMount(Component, {
      propsData: {
        ...defaultProps,
        ...propsData,
      },
      stubs: {
        GlModal,
        GlSprintf,
      },
    });
  };
  beforeEach(() => {
    createWrapper();
  });

  it('has the download button with required attrs', () => {
    const downloadLink = findDownloadLink();

    expect(downloadLink.attributes()).toMatchObject({
      href: defaultProps.downloadLink,
      download: expect.anything(),
    });
  });

  it('should contain the dynamic title', () => {
    createWrapper({ scannedResourcesCount: 20 });
    expect(wrapper.findComponent(GlModal).props('title')).toBe('20 Scanned URLs');
  });

  it('should not show download button when link is not present', () => {
    createWrapper({ downloadLink: '' });
    expect(findDownloadLink().exists()).toBe(false);
  });

  it('scanned urls should be limited to 15', () => {
    createWrapper({
      scannedUrls: Array(20).fill(defaultProps.scannedUrls[0]),
    });
    expect(wrapper.findAll('[data-testid="dast-scanned-url"]')).toHaveLength(15);
  });
});
