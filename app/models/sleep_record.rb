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

  # Validations
  validates :clock_in_time, presence: true

  # Scopes
  scope :for_week, ->(start_date = Time.current) {
    where(clock_in_time: start_date.beginning_of_week..start_date.end_of_week)
  }

  scope :following_records, ->(user) {
    joins(:user)
      .where(users: { id: user.followings.select(:id) })
      .for_week
      .completed
      .order(duration_seconds: :desc)
  }

  scope :desc, -> { order(created_at: :desc) }
  scope :uncompleted, -> { where(clock_out_time: nil) }
  scope :completed, -> { where.not(clock_out_time: nil) }

  def self.clock_out_all
    current_time = Time.current
    formatted_time = current_time.strftime("%Y-%m-%d %H:%M:%S")

    uncompleted.update_all(
      clock_out_time: current_time,
      duration_seconds: Arel.sql("CAST((julianday('#{formatted_time}') - julianday(clock_in_time)) * 86400 AS INTEGER)")
    )
  end
end
