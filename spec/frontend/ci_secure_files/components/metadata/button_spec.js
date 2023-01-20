import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Button from '~/ci_secure_files/components/metadata/button.vue';
import { secureFiles } from '../../mock_data';

const secureFileWithoutMetadata = secureFiles[0];
const secureFileWithMetadata = secureFiles[2];
const modalId = 'metadataModalId';

describe('Secure File Metadata Button', () => {
  let wrapper;

  const findButton = () => wrapper.findComponent(GlButton);

  afterEach(() => {
    wrapper.destroy();
  });

  const createWrapper = (secureFile = {}, admin = false) => {
    wrapper = mount(Button, {
      propsData: {
        admin,
        modalId,
        secureFile,
      },
    });
  };

  describe('when a secure file contains metadata', () => {
    describe('when the user is an admin', () => {
      it('displays the button', () => {
        createWrapper(secureFileWithMetadata, true);

        expect(findButton().isVisible()).toBe(true);
        expect(findButton().attributes('aria-label')).toBe('View File Metadata');
      });
    });

    describe('when the user is not an admin', () => {
      it('does not display the button', () => {
        createWrapper(secureFileWithMetadata, false);

        expect(findButton().exists()).toBe(false);
      });
    });
  });

  describe('when a secure file contains no metadata', () => {
    describe('when the user is an admin', () => {
      it('does not display the button', () => {
        createWrapper(secureFileWithoutMetadata, true);

        expect(findButton().exists()).toBe(false);
      });
    });

    describe('when the user is not an admin', () => {
      it('does not display the button', () => {
        createWrapper(secureFileWithoutMetadata, false);

        expect(findButton().exists()).toBe(false);
      });
    });
  });
});
