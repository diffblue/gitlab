import { mount } from '@vue/test-utils';
import { merge } from 'lodash';
import { nextTick } from 'vue';
import ConfigurationForm from 'ee/security_configuration/api_fuzzing/components/configuration_form.vue';
import { SCAN_MODES } from 'ee/security_configuration/api_fuzzing/constants';
import ConfigurationSnippetModal from 'ee/security_configuration/components/configuration_snippet_modal.vue';
import { CONFIGURATION_SNIPPET_MODAL_ID } from 'ee/security_configuration/components/constants';
import DropdownInput from 'ee/security_configuration/components/dropdown_input.vue';
import DynamicFields from 'ee/security_configuration/components/dynamic_fields.vue';
import FormInput from 'ee/security_configuration/components/form_input.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { CODE_SNIPPET_SOURCE_API_FUZZING } from '~/ci/pipeline_editor/components/code_snippet_alert/constants';
import { apiFuzzingConfigurationQueryResponse } from '../mock_data';

jest.mock('ee/security_configuration/api_fuzzing/utils', () => ({
  buildConfigurationSnippet: jest.fn().mockReturnValue('configuration YAML'),
}));

describe('EE - ApiFuzzingConfigurationForm', () => {
  let wrapper;

  const { apiFuzzingCiConfiguration } = apiFuzzingConfigurationQueryResponse.data.project;

  const findEnableAuthenticationCheckbox = () =>
    wrapper.findByTestId('api-fuzzing-enable-authentication-checkbox');
  const findTargetUrlInput = () => wrapper.findAllComponents(FormInput).at(0);
  const findScanModeInput = () => wrapper.findAllComponents(DropdownInput).at(0);
  const findSpecificationFileInput = () => wrapper.findAllComponents(FormInput).at(1);
  const findAuthenticationNotice = () => wrapper.findByTestId('api-fuzzing-authentication-notice');
  const findAuthenticationFields = () => wrapper.findComponent(DynamicFields);
  const findScanProfileDropdownInput = () => wrapper.findAllComponents(DropdownInput).at(1);
  const findScanProfileYamlViewer = () =>
    wrapper.findByTestId('api-fuzzing-scan-profile-yaml-viewer');
  const findSubmitButton = () => wrapper.findByTestId('api-fuzzing-configuration-submit-button');
  const findCancelButton = () => wrapper.findByTestId('api-fuzzing-configuration-cancel-button');
  const findConfigurationSnippetModal = () => wrapper.findComponent(ConfigurationSnippetModal);

  const setFormData = async () => {
    findTargetUrlInput().vm.$emit('input', 'https://gitlab.com');
    await findScanModeInput().vm.$emit('input', 'HAR');
    findSpecificationFileInput().vm.$emit('input', '/specification/file/path');
    return findScanProfileDropdownInput().vm.$emit(
      'input',
      apiFuzzingCiConfiguration.scanProfiles[0].name,
    );
  };

  const createWrapper = (options = {}) => {
    wrapper = extendedWrapper(
      mount(
        ConfigurationForm,
        merge(
          {
            provide: {
              fullPath: 'namespace/project',
              gitlabCiYamlEditPath: '/ci/editor',
              securityConfigurationPath: '/security/configuration',
              apiFuzzingAuthenticationDocumentationPath:
                'api_fuzzing_authentication/documentation/path',
              ciVariablesDocumentationPath: '/ci_cd_variables/documentation/path',
              projectCiSettingsPath: '/project/settings/ci_cd',
              canSetProjectCiVariables: true,
            },
            propsData: {
              apiFuzzingCiConfiguration,
            },
            mocks: {
              $apollo: {
                mutate: jest.fn(),
              },
            },
          },
          options,
        ),
      ),
    );
  };

  it('includes a link to API fuzzing authentication documentation', () => {
    createWrapper();

    expect(wrapper.html()).toContain('api_fuzzing_authentication/documentation/path');
  });

  describe('scan modes', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('displays a dropdown option for each scan mode', () => {
      findScanModeInput()
        .findAll('li')
        .wrappers.forEach((item, index) => {
          expect(item.text()).toBe(
            SCAN_MODES[apiFuzzingCiConfiguration.scanModes[index]].scanModeLabel,
          );
        });
    });

    it('by default, the specification file input is hidden', () => {
      expect(wrapper.findAllComponents(FormInput)).toHaveLength(1);
    });

    describe.each(Object.keys(SCAN_MODES))('when %s scan mode is selected', (scanMode) => {
      it('the specificationfile input becomes visible and has the correct labels', async () => {
        const selectedScanMode = SCAN_MODES[scanMode];
        findScanModeInput().vm.$emit('input', scanMode);
        await nextTick();

        const specificationFileInput = findSpecificationFileInput();
        expect(specificationFileInput.exists()).toBe(true);
        expect(specificationFileInput.text()).toContain(selectedScanMode.label);
        expect(specificationFileInput.text()).toContain(selectedScanMode.description);
        expect(specificationFileInput.find('input').attributes('placeholder')).toBe(
          selectedScanMode.placeholder,
        );
      });
    });
  });

  describe('authentication', () => {
    it('authentication section is hidden by default', () => {
      createWrapper();

      expect(findAuthenticationNotice().exists()).toBe(false);
    });

    it('authentication section becomes visible once checkbox is checked', async () => {
      createWrapper();
      await findEnableAuthenticationCheckbox().setChecked(true);

      expect(findAuthenticationNotice().exists()).toBe(true);
    });

    it('sees the the proper notice as a maintainer', async () => {
      createWrapper();
      await findEnableAuthenticationCheckbox().setChecked(true);

      expect(findAuthenticationNotice().text()).toMatchInterpolatedText(
        'Make sure your credentials are secured To prevent a security leak, authentication info must be added as a CI variable. As a user with maintainer access rights, you can manage CI variables in the Settings area.',
      );
    });

    it('sees the the proper notice as a developer', async () => {
      createWrapper({
        provide: {
          canSetProjectCiVariables: false,
        },
      });
      await findEnableAuthenticationCheckbox().setChecked(true);

      expect(findAuthenticationNotice().text()).toMatchInterpolatedText(
        "You may need a maintainer's help to secure your credentials. To prevent a security leak, authentication info must be added as a CI variable. A user with maintainer access rights can manage CI variables in the Settings area. We detected that you are not a maintainer. Commit your changes and assign them to a maintainer to update the credentials before merging.",
      );
    });
  });

  describe('scan profiles', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('displays a dropdown option for each scan profile', () => {
      const dropdownItems = findScanProfileDropdownInput().findAll('li').wrappers;
      dropdownItems.shift(); // Skip section header
      dropdownItems.forEach((item, index) => {
        expect(item.text()).toBe(apiFuzzingCiConfiguration.scanProfiles[index].description);
      });
    });

    it('by default, YAML viewer is not visible', () => {
      expect(findScanProfileYamlViewer().exists()).toBe(false);
    });

    it('when a scan profile is selected, its YAML is visible', async () => {
      const [selectedScanProfile] = apiFuzzingCiConfiguration.scanProfiles;
      findScanProfileDropdownInput().vm.$emit('input', selectedScanProfile.name);
      await nextTick();

      expect(findScanProfileYamlViewer().exists()).toBe(true);
      expect(findScanProfileYamlViewer().text()).toBe(selectedScanProfile.yaml.trim());
    });
  });

  describe('form submission', () => {
    it('cancel button points to Security Configuration page', () => {
      createWrapper();

      expect(findCancelButton().attributes('href')).toBe('/security/configuration');
    });

    it('submit button is disabled until all fields are filled', async () => {
      createWrapper();

      expect(findSubmitButton().props('disabled')).toBe(true);

      await setFormData();

      expect(findSubmitButton().props('disabled')).toBe(false);

      await findEnableAuthenticationCheckbox().setChecked(true);

      expect(findSubmitButton().props('disabled')).toBe(true);

      await findAuthenticationFields().vm.$emit('input', [
        {
          ...wrapper.vm.authenticationSettings[0],
          value: '$UsernameVariable',
        },
        {
          ...wrapper.vm.authenticationSettings[1],
          value: '$PasswordVariable',
        },
      ]);

      expect(findSubmitButton().props('disabled')).toBe(false);
    });

    it('opens the modal with the correct props', async () => {
      createWrapper();
      jest.spyOn(wrapper.vm.$refs[CONFIGURATION_SNIPPET_MODAL_ID], 'show');
      await setFormData();
      wrapper.find('form').trigger('submit');
      await nextTick();

      expect(wrapper.vm.$refs[CONFIGURATION_SNIPPET_MODAL_ID].show).toHaveBeenCalled();
      expect(findConfigurationSnippetModal().props()).toEqual({
        ciYamlEditUrl: '/ci/editor',
        yaml: 'configuration YAML',
        redirectParam: CODE_SNIPPET_SOURCE_API_FUZZING,
        scanType: 'API Fuzzing',
      });
    });
  });
});
