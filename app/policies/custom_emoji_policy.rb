# frozen_string_literal: true

class CustomEmojiPolicy < BasePolicy
  delegate { @subject.group }

  condition(:admin_custom_emoji) do
    @subject.group.member?(@user, Gitlab::Access::MAINTAINER) || @subject.creator == @user
  end

  rule { admin_custom_emoji }.policy do
    enable :delete_custom_emoji
  end
end
