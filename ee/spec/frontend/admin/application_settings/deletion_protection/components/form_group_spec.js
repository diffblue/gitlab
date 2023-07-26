import { GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { helpPagePath } from '~/helpers/help_page_helper';
import FormGroup from 'ee/admin/application_settings/deletion_protection/components/form_group.vue';
import { I18N_DELETION_PROTECTION } from 'ee/admin/application_settings/deletion_protection/constants';

describe('Form group component', () => {
  let wrapper;

  const findGlLink = () => wrapper.findComponent(GlLink);

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = mountExtended(FormGroup, {
      propsData: {
        deletionAdjournedPeriod: 7,
        ...props,
      },
      provide,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders an input for setting the deletion adjourned period', () => {
    expect(
      wrapper.findByLabelText(I18N_DELETION_PROTECTION.label, { exact: false }).attributes(),
    ).toMatchObject({
      name: 'application_setting[deletion_adjourned_period]',
      type: 'number',
      min: '1',
      max: '90',
    });
  });

  it('displays the help text', () => {
    expect(wrapper.findByText(I18N_DELETION_PROTECTION.helpText).exists()).toBe(true);
  });

  it('displays the help link', () => {
    expect(findGlLink().text()).toContain(I18N_DELETION_PROTECTION.learnMore);
    expect(findGlLink().attributes('href')).toBe(
      helpPagePath('administration/settings/visibility_and_access_controls', {
        anchor: 'delayed-project-deletion',
      }),
    );
  });
});
