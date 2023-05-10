import { GlAlert, GlForm, GlCollapsibleListbox } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import AdminEmailsForm from 'ee/admin/emails/components/admin_emails_form.vue';
import * as RestApi from '~/rest_api';
import { __ } from '~/locale';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));
jest.mock('~/rest_api');

describe('AdminEmailsForm', () => {
  let wrapper;

  const defaultProvide = {
    adminEmailPath: '/admin/email',
    adminEmailsAreCurrentlyRateLimited: false,
  };

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = mountExtended(AdminEmailsForm, {
      attachTo: document.body,
      provide: { ...defaultProvide, ...provide },
    });
  };

  const findSubjectField = () => {
    return wrapper.findByLabelText(AdminEmailsForm.fields.subject.label);
  };
  const findBodyField = () => wrapper.findByLabelText(AdminEmailsForm.fields.body.label);
  const findSubjectValidationMessage = () => wrapper.findByText('Subject is required.');
  const findBodyValidationMessage = () => wrapper.findByText('Body is required.');
  const findRecipientsValidationMessage = () =>
    wrapper.findByText('Recipient group or project is required.');
  const submitForm = async () => {
    wrapper.findComponent(GlForm).trigger('submit');
    await nextTick();
  };
  const findSubmitButton = () =>
    wrapper.findByRole('button', { name: AdminEmailsForm.i18n.submitButton });
  const findGlListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const showGlListbox = async () => {
    findGlListbox().vm.$emit('shown');
    await nextTick();
  };

  const mockSuccessfulApiRequests = () => {
    RestApi.getGroups = jest.fn().mockResolvedValueOnce([
      { id: 1, full_name: 'Group Foo' },
      { id: 2, full_name: 'Group Bar' },
    ]);
    RestApi.getProjects = jest.fn().mockResolvedValueOnce({
      data: [
        { id: 1, name_with_namespace: 'Project Foo' },
        { id: 2, name_with_namespace: 'Project Bar' },
      ],
    });
  };

  it('sets form `action`', () => {
    createComponent();

    expect(wrapper.attributes('action')).toBe(defaultProvide.adminEmailPath);
  });

  it('renders hidden CSRF input', () => {
    createComponent();

    expect(
      wrapper.find('input[type="hidden"][name="authenticity_token"]').attributes('value'),
    ).toBe('mock-csrf-token');
  });

  it('renders `Subject` field', () => {
    createComponent();

    expect(findSubjectField().exists()).toBe(true);
  });

  it('renders `Body` field', () => {
    createComponent();

    expect(findBodyField().exists()).toBe(true);
  });

  describe('`Recipient group or project` field', () => {
    describe('when dropdown is shown', () => {
      it('calls API and adds items to dropdown', async () => {
        mockSuccessfulApiRequests();
        createComponent();

        expect(RestApi.getGroups).not.toHaveBeenCalled();
        expect(RestApi.getProjects).not.toHaveBeenCalled();

        await showGlListbox();

        expect(RestApi.getGroups).toHaveBeenCalled();
        expect(RestApi.getProjects).toHaveBeenCalled();
        expect(findGlListbox().props('loading')).toBe(true);

        await waitForPromises();

        expect(findGlListbox().props('items')).toEqual([
          {
            value: 'all',
            text: __('All groups and projects'),
          },
          { value: 'group-1', text: 'Group Foo' },
          { value: 'group-2', text: 'Group Bar' },
          { value: 'project-1', text: 'Project Foo' },
          { value: 'project-2', text: 'Project Bar' },
        ]);
      });

      describe('when API request fails', () => {
        it('shows error alert', async () => {
          RestApi.getGroups = jest.fn().mockRejectedValueOnce();
          RestApi.getProjects = jest.fn().mockRejectedValueOnce();

          createComponent();

          await showGlListbox();
          await waitForPromises();

          expect(wrapper.findComponent(GlAlert).text()).toBe(AdminEmailsForm.i18n.errorMessage);
        });
      });
    });

    describe('when dropdown is searched', () => {
      it('calls API with search term and updates dropdown items', async () => {
        mockSuccessfulApiRequests();
        createComponent();

        await showGlListbox();

        RestApi.getGroups = jest
          .fn()
          .mockResolvedValueOnce([{ id: 3, full_name: 'Searched Group Foo' }]);
        RestApi.getProjects = jest.fn().mockResolvedValueOnce({
          data: [{ id: 3, name_with_namespace: 'Searched Project Foo' }],
        });

        findGlListbox().vm.$emit('search', 'Foo');
        await nextTick();

        expect(RestApi.getGroups).toHaveBeenCalledWith('Foo', {});
        expect(RestApi.getProjects).toHaveBeenCalledWith('Foo', {
          order_by: 'id',
          membership: false,
        });
        expect(findGlListbox().props('searching')).toBe(true);

        await waitForPromises();

        expect(findGlListbox().props('items')).toEqual([
          { value: 'group-3', text: 'Searched Group Foo' },
          { value: 'project-3', text: 'Searched Project Foo' },
        ]);
      });

      describe('when API returns no results', () => {
        it('shows empty message', async () => {
          mockSuccessfulApiRequests();
          createComponent();

          await showGlListbox();

          RestApi.getGroups = jest.fn().mockResolvedValueOnce([]);
          RestApi.getProjects = jest.fn().mockResolvedValueOnce({
            data: [],
          });

          findGlListbox().vm.$emit('search', 'Foo');

          await waitForPromises();

          expect(findGlListbox().props('items')).toEqual([]);
          expect(findGlListbox().props('noResultsText')).toBe(
            AdminEmailsForm.i18n.noResultsMessage,
          );
        });
      });
    });

    describe('when dropdown item is selected', () => {
      it('shows item as selected and updates hidden input', async () => {
        mockSuccessfulApiRequests();
        createComponent();

        await showGlListbox();
        await waitForPromises();

        findGlListbox().vm.$emit('select', 'group-1');
        await nextTick();

        expect(findGlListbox().props('selected')).toBe('group-1');
        expect(wrapper.find('input[name="recipients"]').element.value).toBe('group-1');
      });
    });
  });

  describe('when fields are empty', () => {
    it('renders validation messages', async () => {
      createComponent();

      await submitForm();

      expect(findSubjectValidationMessage().exists()).toBe(true);
      expect(findBodyValidationMessage().exists()).toBe(true);
      expect(findRecipientsValidationMessage().exists()).toBe(true);
    });
  });

  describe('when fields are not empty', () => {
    it('does not render validation messages', async () => {
      createComponent();

      await findSubjectField().setValue('Foo');

      await submitForm();

      expect(findSubjectValidationMessage().exists()).toBe(false);
    });
  });

  describe('when `adminEmailsAreCurrentlyRateLimited` is `true`', () => {
    it('disables submit button', () => {
      createComponent({
        provide: {
          adminEmailsAreCurrentlyRateLimited: true,
        },
      });

      expect(findSubmitButton().props('disabled')).toBe(true);
    });
  });
});
