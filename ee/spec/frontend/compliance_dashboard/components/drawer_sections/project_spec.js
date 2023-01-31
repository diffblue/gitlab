import { GlAvatarLabeled, GlAvatarLink, GlLabel } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Project from 'ee/compliance_dashboard/components/violations_report/drawer_sections/project.vue';
import DrawerSectionHeader from 'ee/compliance_dashboard/components/violations_report/shared/drawer_section_header.vue';
import { complianceFramework } from '../../mock_data';

describe('Project component', () => {
  let wrapper;
  const projectName = 'Foo project';
  const url = 'https://foo.com/project';
  const avatarUrl = '/foo/bar.png';

  const findSectionHeader = () => wrapper.findComponent(DrawerSectionHeader);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findAvatarLabel = () => wrapper.findComponent(GlAvatarLabeled);
  const findComplianceFrameworkLabel = () => wrapper.findComponent(GlLabel);

  const createComponent = (props) => {
    return shallowMount(Project, {
      propsData: {
        name: projectName,
        url,
        complianceFramework: {},
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('by default', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the header', () => {
      expect(findSectionHeader().text()).toBe('Project');
    });

    it('renders the avatar with a name and url', () => {
      expect(findAvatarLink().attributes()).toStrictEqual({
        title: projectName,
        href: url,
      });

      expect(findAvatarLabel().props()).toMatchObject({
        subLabel: projectName,
        label: '',
      });
      expect(findAvatarLabel().attributes()).toMatchObject({
        'entity-name': projectName,
        src: '',
      });
    });

    it('does not render the compliance framework label', () => {
      expect(findComplianceFrameworkLabel().exists()).toBe(false);
    });
  });

  describe('when the avatar URL is provided', () => {
    beforeEach(() => {
      wrapper = createComponent({ avatarUrl });
    });

    it('renders the avatar with the URL', () => {
      expect(findAvatarLabel().props()).toMatchObject({
        subLabel: projectName,
        label: '',
      });
      expect(findAvatarLabel().attributes()).toMatchObject({
        'entity-name': projectName,
        src: avatarUrl,
      });
    });
  });

  describe('when the compliance framework is provided', () => {
    beforeEach(() => {
      wrapper = createComponent({ complianceFramework });
    });

    it('renders the compliance framework label', () => {
      const { color, description, name } = complianceFramework;

      expect(findComplianceFrameworkLabel().props()).toMatchObject({
        backgroundColor: color,
        description,
        title: name,
        size: 'sm',
      });
    });
  });
});
