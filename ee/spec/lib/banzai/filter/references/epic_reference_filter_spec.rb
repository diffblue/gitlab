# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::EpicReferenceFilter do
  include FilterSpecHelper

  let(:urls) { Gitlab::Routing.url_helpers }

  let(:group) { create(:group) }
  let(:another_group) { create(:group) }
  let(:epic) { create(:epic, group: group) }
  let(:full_ref_text) { "Check #{epic.group.full_path}&#{epic.iid}" }

  def doc(reference = nil)
    reference ||= "Check &#{epic.iid}"
    context = { project: nil, group: group }

    reference_filter(reference, context)
  end

  context 'internal reference' do
    let(:reference) { "&#{epic.iid}" }
    let(:epic_url) { urls.group_epic_url(group, epic) }

    it 'links to a valid reference' do
      expect(doc.css('a').first.attr('href')).to eq(urls.group_epic_url(group, epic))
    end

    it 'links with adjacent text' do
      expect(doc.text).to eq("Check #{reference}")
    end

    it 'includes a title attribute' do
      expect(doc.css('a').first.attr('title')).to eq(epic.title)
    end

    it 'escapes the title attribute' do
      epic.update_attribute(:title, %{"></a>whatever<a title="})

      expect(doc.text).to eq("Check #{reference}")
    end

    it 'includes default classes' do
      expect(doc.css('a').first.attr('class')).to eq('gfm gfm-epic has-tooltip')
    end

    it 'includes a data-group attribute' do
      link = doc.css('a').first

      expect(link).to have_attribute('data-group')
      expect(link.attr('data-group')).to eq(group.id.to_s)
    end

    it 'includes a data-epic attribute' do
      link = doc.css('a').first

      expect(link).to have_attribute('data-epic')
      expect(link.attr('data-epic')).to eq(epic.id.to_s)
    end

    it 'includes a data-original attribute' do
      link = doc.css('a').first

      expect(link).to have_attribute('data-original')
      expect(link.attr('data-original')).to eq(CGI.escapeHTML(reference))
    end

    it 'includes a data-reference-format attribute' do
      link = doc("#{reference}+").css('a').first

      expect(link).to have_attribute('data-reference-format')
      expect(link.attr('data-reference-format')).to eq('+')
      expect(link.attr('href')).to eq(epic_url)
    end

    it 'includes a data-reference-format attribute for URL references' do
      link = doc("#{epic_url}+").css('a').first

      expect(link).to have_attribute('data-reference-format')
      expect(link.attr('data-reference-format')).to eq('+')
      expect(link.attr('href')).to eq(epic_url)
    end

    it 'ignores invalid epic IIDs' do
      text = "Check &#{non_existing_record_iid}"

      expect(doc(text).to_s).to eq(ERB::Util.html_escape_once(text))
    end

    it 'ignores out of range epic IDs' do
      text = "Check &1161452270761535925900804973910297"

      expect(doc(text).to_s).to eq(ERB::Util.html_escape_once(text))
    end

    it 'does not process links containing epic numbers followed by text' do
      href = "#{reference}st"
      link = doc("<a href='#{href}'></a>").css('a').first.attr('href')

      expect(link).to eq(href)
    end
  end

  context 'internal escaped reference' do
    let(:reference) { "&amp;#{epic.iid}" }

    it 'links to a valid reference' do
      expect(doc.css('a').first.attr('href')).to eq(urls.group_epic_url(group, epic))
    end

    it 'includes a title attribute' do
      expect(doc.css('a').first.attr('title')).to eq(epic.title)
    end

    it 'includes default classes' do
      expect(doc.css('a').first.attr('class')).to eq('gfm gfm-epic has-tooltip')
    end

    it 'ignores invalid epic IIDs' do
      text = "Check &amp;#{non_existing_record_iid}"

      expect(doc(text).to_s).to eq(ERB::Util.html_escape_once(text))
    end
  end

  context 'cross-reference' do
    before do
      epic.update_attribute(:group_id, another_group.id)
    end

    it 'ignores a shorthand reference from another group' do
      text = "Check &#{epic.iid}"

      expect(doc(text).to_s).to eq(ERB::Util.html_escape_once(text))
    end

    it 'links to a valid reference for full reference' do
      expect(doc(full_ref_text).css('a').first.attr('href')).to eq(urls.group_epic_url(another_group, epic))
    end

    it 'link has valid text' do
      expect(doc(full_ref_text).css('a').first.text).to eq("#{epic.group.full_path}&#{epic.iid}")
    end

    it 'includes default classes' do
      expect(doc(full_ref_text).css('a').first.attr('class')).to eq('gfm gfm-epic has-tooltip')
    end
  end

  context 'escaped cross-reference' do
    before do
      epic.update_attribute(:group_id, another_group.id)
    end

    it 'ignores a shorthand reference from another group' do
      text = "Check &amp;#{epic.iid}"

      expect(doc(text).to_s).to eq(ERB::Util.html_escape_once(text))
    end

    it 'links to a valid reference for full reference' do
      expect(doc(full_ref_text).css('a').first.attr('href')).to eq(urls.group_epic_url(another_group, epic))
    end

    it 'link has valid text' do
      expect(doc(full_ref_text).css('a').first.text).to eq("#{epic.group.full_path}&#{epic.iid}")
    end

    it 'includes default classes' do
      expect(doc(full_ref_text).css('a').first.attr('class')).to eq('gfm gfm-epic has-tooltip')
    end
  end

  context 'subgroup cross-reference' do
    before do
      subgroup = create(:group, parent: another_group)
      epic.update_attribute(:group_id, subgroup.id)
    end

    it 'ignores a shorthand reference from another group' do
      text = "Check &#{epic.iid}"

      expect(doc(text).to_s).to eq(ERB::Util.html_escape_once(text))
    end

    it 'ignores reference with incomplete group path' do
      text = "Check @#{epic.group.path}&#{epic.iid}"

      expect(doc(text).to_s).to eq(ERB::Util.html_escape_once(text))
    end

    it 'links to a valid reference for full reference' do
      expect(doc(full_ref_text).css('a').first.attr('href')).to eq(urls.group_epic_url(epic.group, epic))
    end

    it 'link has valid text' do
      expect(doc(full_ref_text).css('a').first.text).to eq("#{epic.group.full_path}&#{epic.iid}")
    end

    it 'includes default classes' do
      expect(doc(full_ref_text).css('a').first.attr('class')).to eq('gfm gfm-epic has-tooltip')
    end
  end

  context 'url reference' do
    let(:link) { urls.group_epic_url(epic.group, epic) }
    let(:text) { "Check #{link}" }
    let(:project) { create(:project) }

    before do
      epic.update_attribute(:group_id, another_group.id)
    end

    it 'links to a valid reference' do
      expect(doc(text).css('a').first.attr('href')).to eq(urls.group_epic_url(another_group, epic))
    end

    it 'link has valid text' do
      expect(doc(text).css('a').first.text).to eq(epic.to_reference(group))
    end

    it 'includes default classes' do
      expect(doc(text).css('a').first.attr('class')).to eq('gfm gfm-epic has-tooltip')
    end

    it 'matches link reference with trailing slash' do
      doc2 = reference_filter("Fixed (#{link}/.)")

      expect(doc2).to match(%r{\(#{Regexp.escape(epic.to_reference(group))}\.\)})
    end
  end

  context 'full cross-refererence in a link href' do
    let(:link) { "#{another_group.path}&#{epic.iid}" }
    let(:text) do
      ref = %{<a href="#{link}">Reference</a>}
      "Check #{ref}"
    end

    before do
      epic.update_attribute(:group_id, another_group.id)
    end

    it 'links to a valid reference for link href' do
      expect(doc(text).css('a').first.attr('href')).to eq(urls.group_epic_url(another_group, epic))
    end

    it 'link has valid text' do
      expect(doc(text).css('a').first.text).to eq('Reference')
    end

    it 'includes default classes' do
      expect(doc(text).css('a').first.attr('class')).to eq('gfm gfm-epic has-tooltip')
    end
  end

  context 'url in a link href' do
    let(:link) { urls.group_epic_url(epic.group, epic) }
    let(:text) do
      ref = %{<a href="#{link}">Reference</a>}
      "Check #{ref}"
    end

    before do
      epic.update_attribute(:group_id, another_group.id)
    end

    it 'links to a valid reference for link href' do
      expect(doc(text).css('a').first.attr('href')).to eq(urls.group_epic_url(another_group, epic))
    end

    it 'link has valid text' do
      expect(doc(text).css('a').first.text).to eq('Reference')
    end

    it 'includes default classes' do
      expect(doc(text).css('a').first.attr('class')).to eq('gfm gfm-epic has-tooltip')
    end
  end

  context 'checking N+1' do
    let(:epic2) { create(:epic, group: another_group) }
    let(:project) { create(:project, group: another_group) }
    let(:full_ref_text) { "#{epic.group.full_path}&#{epic.iid}" }
    let(:context) { { project: nil, group: group } }

    it 'does not have N+1 per multiple references per group', :use_sql_query_cache do
      markdown = "#{epic.to_reference} &9999990"

      # warm up
      reference_filter(markdown, context)

      control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        reference_filter(markdown, context)
      end.count

      expect(control_count).to eq 1

      markdown = "#{epic.to_reference} #{epic.group.full_path}&9999991 #{epic.group.full_path}&9999992 &9999993 #{epic2.to_reference(group)} #{epic2.group.full_path}&9999991 something/cool&12"

      # Since we're not batching queries across groups,
      # we have to account for that.
      # 1 for both groups, 1 for epics in each group == 3
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/330359
      max_count = control_count + 2

      expect do
        reference_filter(markdown, context)
      end.not_to exceed_all_query_limit(max_count)
    end
  end
end
