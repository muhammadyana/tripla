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
#  index_sleep_records_on_user_id                    (user_id)
#  index_sleep_records_on_user_id_and_clock_in_time  (user_id,clock_in_time)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class SleepRecordSerializer < ApplicationSerializer
  attributes :id, :clock_in_time, :clock_out_time, :duration_seconds, :user_id, :created_at, :updated_at
end
