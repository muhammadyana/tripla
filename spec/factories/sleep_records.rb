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
FactoryBot.define do
  factory :sleep_record do
    association :user

    clock_in_time { Faker::Time.between(from: 2.days.ago, to: 1.day.ago, period: :evening) }
    clock_out_time { |n| n.clock_in_time + rand(6..9).hours }
    duration_seconds { |n| (n.clock_out_time - n.clock_in_time).to_i }
  end
end
