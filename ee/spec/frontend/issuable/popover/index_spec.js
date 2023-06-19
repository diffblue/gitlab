import { setHTMLFixture } from 'helpers/fixtures';
import * as createDefaultClient from '~/lib/graphql';
import initIssuablePopovers, * as popover from 'ee/issuable/popover/index';

createDefaultClient.default = jest.fn();

describe('initIssuablePopoversEE', () => {
  let epicWithPopover;
  let epicWithoutPopover;

  beforeEach(() => {
    setHTMLFixture(`
      <div id="epicWithPopover" class="gfm-epic" title="title" data-iid="1" data-group-path="gitlab-org" data-reference-type="epic">
        Epic1
      </div>
      <div id="epicWithoutPopover" class="gfm-epic" title="title" data-reference-type="epic">
        Epic2
      </div>
    `);

    epicWithPopover = document.querySelector('#epicWithPopover');
    epicWithoutPopover = document.querySelector('#epicWithoutPopover');
  });

  describe('init function', () => {
    beforeEach(() => {
      epicWithPopover.addEventListener = jest.fn();
      epicWithoutPopover.addEventListener = jest.fn();
    });

    it('does not add the same event listener twice', () => {
      initIssuablePopovers([epicWithPopover]);

      expect(epicWithPopover.addEventListener).toHaveBeenCalledTimes(1);
    });

    it('does not add listener if it does not have the necessary data attributes', () => {
      initIssuablePopovers([epicWithoutPopover]);

      expect(epicWithoutPopover.addEventListener).not.toHaveBeenCalled();
    });
  });

  describe('mount function', () => {
    beforeEach(() => {
      jest.spyOn(popover, 'handleIssuablePopoverMount').mockImplementation(jest.fn());
    });

    it('calls popover mount function with components for an Epic', async () => {
      initIssuablePopovers([epicWithPopover], popover.handleIssuablePopoverMount);

      await epicWithPopover.dispatchEvent(new Event('mouseenter', { target: epicWithPopover }));

      expect(popover.handleIssuablePopoverMount).toHaveBeenCalledWith(
        expect.objectContaining({
          apolloProvider: expect.anything(),
          iid: '1',
          namespacePath: 'gitlab-org',
          title: 'title',
          referenceType: 'epic',
          target: epicWithPopover,
        }),
      );
    });
  });
});
