import VueApollo from 'vue-apollo';
import { createLocalVue } from '@vue/test-utils';
import { GlFormInput, GlForm } from '@gitlab/ui';
import createFlash from '~/flash';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import externalAuditEventDestinationCreate from 'ee/audit_events/graphql/create_external_destination.mutation.graphql';
import StreamDestinationEditor from 'ee/audit_events/components/stream/stream_destination_editor.vue';
import { AUDIT_STREAMS_NETWORK_ERRORS, ADD_STREAM_EDITOR_I18N } from 'ee/audit_events/constants';
import { destinationCreateMutationPopulator, groupPath } from '../../mock_data';

jest.mock('~/flash');
const localVue = createLocalVue();
localVue.use(VueApollo);
const externalAuditEventDestinationCreateSpy = jest
  .fn()
  .mockResolvedValue(destinationCreateMutationPopulator());

describe('StreamDestinationEditor', () => {
  let wrapper;

  const createComponent = (
    destinationCreateMutationSpy = externalAuditEventDestinationCreateSpy,
  ) => {
    const mockApollo = createMockApollo([
      [externalAuditEventDestinationCreate, destinationCreateMutationSpy],
    ]);
    wrapper = mountExtended(StreamDestinationEditor, {
      provide: {
        groupPath,
      },
      apolloProvider: mockApollo,
      localVue,
    });
  };

  const findDestinationForm = () => wrapper.findComponent(GlForm);
  const findCancelBtn = () => wrapper.findByTestId('stream-destination-cancel-button');
  const setDestinationUrl = () =>
    wrapper.findComponent(GlFormInput).setValue(ADD_STREAM_EDITOR_I18N.PLACEHOLDER);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    externalAuditEventDestinationCreateSpy.mockClear();
    createFlash.mockClear();
  });

  describe('when initialized', () => {
    it('should render correctly', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('add destination event', () => {
    it('should emit add event after destination added', async () => {
      await setDestinationUrl();
      await findDestinationForm().trigger('submit');
      await waitForPromises();

      expect(createFlash).not.toHaveBeenCalled();
      expect(wrapper.emitted('added')).toBeDefined();
    });

    it('should not emit add destination event and reports error when server returns error', async () => {
      const errorMsg = 'Destination hosts limit exceeded';
      createComponent(jest.fn().mockResolvedValue(destinationCreateMutationPopulator([errorMsg])));
      await setDestinationUrl();
      await findDestinationForm().trigger('submit');
      await waitForPromises();

      expect(createFlash).toHaveBeenCalledWith({
        message: errorMsg,
      });
      expect(wrapper.emitted('added')).not.toBeDefined();
    });

    it('should not emit add destination event and reports error when network error occurs', async () => {
      createComponent(jest.fn().mockRejectedValue());
      await setDestinationUrl();
      await findDestinationForm().trigger('submit');
      await waitForPromises();

      expect(createFlash).toHaveBeenCalledWith({
        message: AUDIT_STREAMS_NETWORK_ERRORS.CREATING_ERROR,
      });
      expect(wrapper.emitted('added')).not.toBeDefined();
    });
  });

  describe('cancel event', () => {
    it('should emit cancel event correctly', async () => {
      await findCancelBtn().trigger('click');

      expect(wrapper.emitted('cancel')).toBeDefined();
    });
  });
});
