import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StorageTypeHelpLink from 'ee/usage_quotas/storage/components/storage_type_help_link.vue';
import { projectHelpLinks } from 'jest/usage_quotas/storage/mock_data';

let wrapper;

const createComponent = ({ props = {} } = {}) => {
  wrapper = shallowMount(StorageTypeHelpLink, {
    propsData: {
      helpLinks: projectHelpLinks,
      ...props,
    },
  });
};

const findLink = () => wrapper.findComponent(GlLink);

describe('StorageTypeHelpLink', () => {
  describe('Storage type w/ link', () => {
    describe.each(Object.entries(projectHelpLinks))('%s', (storageType, url) => {
      beforeEach(() => {
        createComponent({
          props: {
            storageType,
          },
        });
      });

      it('will have proper href', () => {
        expect(findLink().attributes('href')).toBe(url);
      });
    });
  });

  describe('Storage type w/o help link', () => {
    beforeEach(() => {
      createComponent({
        props: {
          storageType: 'Yellow Submarine',
        },
      });
    });

    it('will not have a href', () => {
      expect(findLink().attributes('href')).toBe(undefined);
    });
  });
});
