# frozen_string_literal: true

module SeatCountAlertHelper
  def show_seat_count_alert?
    @seat_count_data.present? && @seat_count_data[:namespace].present?
  end

  def remaining_seat_count
    @seat_count_data[:remaining_seat_count]
  end

  def total_seat_count
    @seat_count_data[:total_seat_count]
  end

  def namespace
    @seat_count_data[:namespace]
  end
end
