# == Schema Information
#
# Table name: sleep_records
#
#  id               :integer          not null, primary key
#  clock_in_time    :datetime
#  clock_out_time   :datetime
#  duration_seconds :integer          default(0)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :integer          not null
#
# Indexes
#
#  index_sleep_records_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class SleepRecord < ApplicationRecord
  # Relationships
  belongs_to :user
  before_save :calculate_duration

  # Validations
  validates :clock_in_time, presence: true

  # Scopes
  scope :for_week, ->(start_date = Time.current) {
    where(clock_in_time: start_date.beginning_of_week..start_date.end_of_week)
  }
  scope :desc, -> { order(created_at: :desc) }
  scope :completed, -> { where.not(clock_out_time: nil) }

  private

  def calculate_duration
    return unless clock_in_time && clock_out_time

    self.duration_seconds = (clock_out_time - clock_in_time).to_i
  end
end
