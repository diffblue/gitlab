import { mount } from '@vue/test-utils';
import JiraIssuesFields from '~/integrations/edit/components/jira_issues_fields.vue';
import { GlFormCheckbox, GlFormInput } from '@gitlab/ui';

describe('JiraIssuesFields', () => {
  let wrapper;

  const defaultProps = {
    showJiraIssuesIntegration: true,
    editProjectPath: '/edit',
  };

  const createComponent = props => {
    wrapper = mount(JiraIssuesFields, {
      propsData: { ...defaultProps, ...props },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findEnableCheckbox = () => wrapper.find(GlFormCheckbox);
  const findProjectKey = () => wrapper.find(GlFormInput);
  const expectedBannerText = 'This is a Premium feature';

  describe('template', () => {
    describe('upgrade banner for non-Premium user', () => {
      beforeEach(() => {
        createComponent({ initialProjectKey: '', showJiraIssuesIntegration: false });
      });

      it('shows upgrade banner', () => {
        expect(wrapper.text()).toContain(expectedBannerText);
      });

      it('does not show checkbox and input field', () => {
        expect(findEnableCheckbox().exists()).toBe(false);
        expect(findProjectKey().exists()).toBe(false);
      });
    });

    describe('Enable Jira issues checkbox', () => {
      beforeEach(() => {
        createComponent({ initialProjectKey: '' });
      });

      it('does not show upgrade banner', () => {
        expect(wrapper.text()).not.toContain(expectedBannerText);
      });

      // As per https://vuejs.org/v2/guide/forms.html#Checkbox-1,
      // browsers don't include unchecked boxes in form submissions.
      it('includes issues_enabled as false even if unchecked', () => {
        expect(wrapper.contains('input[name="service[issues_enabled]"]')).toBe(true);
      });

      it('disables project_key input', () => {
        expect(findProjectKey().attributes('disabled')).toBe('disabled');
      });

      it('does not require project_key', () => {
        expect(findProjectKey().attributes('required')).toBeUndefined();
      });

      describe('on enable issues', () => {
        it('enables project_key input', () => {
          findEnableCheckbox().vm.$emit('input', true);

          return wrapper.vm.$nextTick().then(() => {
            expect(findProjectKey().attributes('disabled')).toBeUndefined();
          });
        });

        it('requires project_key input', () => {
          findEnableCheckbox().vm.$emit('input', true);

          return wrapper.vm.$nextTick().then(() => {
            expect(findProjectKey().attributes('required')).toBe('required');
          });
        });
      });
    });

    it('contains link to editProjectPath', () => {
      createComponent();

      expect(wrapper.contains(`a[href="${defaultProps.editProjectPath}"]`)).toBe(true);
    });
  });
});
