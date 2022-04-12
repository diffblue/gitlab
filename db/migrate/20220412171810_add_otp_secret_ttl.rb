# frozen_string_literal: true

class AddOtpSecretTtl < Gitlab::Database::Migration[1.0]
  def change
    # rubocop: disable Migration/AddColumnsToWideTables
    add_column :users, :otp_secret_ttl, :datetime_with_timezone
    # rubocop: enable Migration/AddColumnsToWideTables
  end
end
