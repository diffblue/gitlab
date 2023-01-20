import { GlModal } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';

import Modal from '~/ci_secure_files/components/metadata/modal.vue';

import { secureFiles } from '../../mock_data';

const cerFile = secureFiles[2];
const modalId = 'metadataModalId';

describe('Secure File Metadata Modal', () => {
  let wrapper;
  let trackingSpy;

  const findModal = () => wrapper.findComponent(GlModal);
  const findRows = () => findModal().findAll('tbody tr');
  const findRowAt = (i) => findRows().at(i);
  const findCell = (i, col) => findRowAt(i).findAll('td').at(col);

  const createWrapper = (secureFile = {}) => {
    wrapper = mount(Modal, {
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
      },

      propsData: {
        modalId,
        secureFile,
      },
    });
  };

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
  });

  afterEach(() => {
    unmockTracking();
    wrapper.destroy();
  });

  describe('when a .cer file is supplied', () => {
    it('displays the modal with the expected file attributes', () => {
      createWrapper(cerFile);
      expect(findModal().isVisible()).toBe(true);
      expect(wrapper.find('table').exists()).toBe(true);

      expect(findModal().text()).toContain('myfile.cer Metadata');

      expect(findCell(0, 0).text()).toBe('Name');
      expect(findCell(1, 0).text()).toBe('Serial');
      expect(findCell(2, 0).text()).toBe('Team');
      expect(findCell(3, 0).text()).toBe('Issuer');
      expect(findCell(4, 0).text()).toBe('Expires at');

      expect(findCell(0, 1).text()).toBe('Apple Distribution: Team Name (ABC123XYZ)');
      expect(findCell(1, 1).text()).toBe('33669367788748363528491290218354043267');
      expect(findCell(2, 1).text()).toBe('Team Name (ABC123XYZ)');
      expect(findCell(3, 1).text()).toBe(
        'Apple Worldwide Developer Relations Certification Authority - G3',
      );
      expect(findCell(4, 1).text()).toBe('April 26, 2022 at 7:20:40 PM GMT');
    });
  });

  describe('event tracking', () => {
    it('sends tracking information when the modal is loaded', () => {
      createWrapper(cerFile);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'load_secure_file_metadata_cer', {});
    });
  });
});
