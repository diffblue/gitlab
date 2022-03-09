import { GlTab } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EpicTabs from 'ee/epic/components/epic_tabs.vue';
import waitForPromises from 'helpers/wait_for_promises';

const treeTabpaneID = 'tree';
const roadmapTabpaneID = 'roadmap';
const containerSelector = 'js-epic-container';
const displayNoneClass = 'gl-display-none';
const containerClass = 'container-limited';

describe('EpicTabs', () => {
  let wrapper;

  const createComponent = ({ provide = {} } = {}) => {
    return shallowMountExtended(EpicTabs, {
      provide: {
        treeElementSelector: `#${treeTabpaneID}`,
        roadmapElementSelector: `#${roadmapTabpaneID}`,
        containerElementSelector: `.${containerSelector}`,
        ...provide,
      },
      stubs: {
        GlTab,
      },
    });
  };

  const findEpicTreeTab = () => wrapper.findByTestId('epic-tree-tab');
  const findEpicRoadmapTab = () => wrapper.findByTestId('epic-roadmap-tab');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default bahviour', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('displays the tabs component', () => {
      expect(wrapper.findByTestId('tabs').exists()).toBe(true);
    });

    it('displays the tree tab', () => {
      const treeTab = findEpicTreeTab();
      expect(treeTab.exists()).toBe(true);
      expect(treeTab.text()).toBe('Issues');
    });

    it('does not display the roadmap tab', () => {
      expect(findEpicRoadmapTab().exists()).toBe(false);
    });
  });

  describe('allowSubEpics = true', () => {
    it('displays the correct tree tab text', () => {
      wrapper = createComponent({ provide: { allowSubEpics: true } });

      const treeTab = findEpicTreeTab();
      expect(treeTab.exists()).toBe(true);
      expect(treeTab.text()).toBe('Epics and Issues');
      expect(treeTab.props().selected).toBe(true);
    });

    it('displays the roadmap tab', () => {
      wrapper = createComponent({ provide: { allowSubEpics: true } });

      const treeTab = findEpicRoadmapTab();
      expect(treeTab.exists()).toBe(true);
      expect(treeTab.text()).toBe('Roadmap');
      expect(treeTab.props().selected).toBe(false);
    });

    const treeTabFixture = `
      <div class="${containerSelector}">
        <div id="${treeTabpaneID}" class="${displayNoneClass}"></div>
        <div id="${roadmapTabpaneID}"></div>
      </div>
    `;

    const roadmapFixture = `
      <div class="${containerSelector} ${containerClass}">
        <div id="${treeTabpaneID}"></div>
        <div id="${roadmapTabpaneID}" class="${displayNoneClass}"></div>
      </div>
    `;

    const treeExamples = [
      ['hides the roadmap tab content', `#${roadmapTabpaneID}`, false, displayNoneClass],
      ['displays the tree tab content', `#${treeTabpaneID}`, true, displayNoneClass],
      ['sets the container to limtied width', `.${containerSelector}`, false, containerClass],
    ];

    const roadmapExamples = [
      ['hides the tree tab content', `#${treeTabpaneID}`, false, displayNoneClass],
      ['displays the roadmap tab content', `#${roadmapTabpaneID}`, true, displayNoneClass],
      ['removes the container width', `.${containerSelector}`, true, containerClass],
    ];

    describe.each`
      targetTab           | tabTestId             | fixture           | examples
      ${treeTabpaneID}    | ${'epic-tree-tab'}    | ${treeTabFixture} | ${treeExamples}
      ${roadmapTabpaneID} | ${'epic-roadmap-tab'} | ${roadmapFixture} | ${roadmapExamples}
    `('on $targetTab tab click', ({ tabTestId, fixture, examples }) => {
      beforeEach(() => {
        setFixtures(fixture);
        wrapper = createComponent({ provide: { allowSubEpics: true } });
      });

      it.each(examples)('%s', async (description, tabPaneSelector, hasClassName, className) => {
        const element = document.querySelector(tabPaneSelector);

        expect(element.classList.contains(className)).toBe(hasClassName);

        wrapper.findByTestId(tabTestId).vm.$emit('click');

        await waitForPromises();

        expect(element.classList.contains(className)).not.toBe(hasClassName);
      });
    });
  });
});
