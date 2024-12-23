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
FactoryBot.define do
  factory :sleep_record do
    association :user
    clock_in_time { Time.current }
    clock_out_time { nil }

    factory :completed_sleep_record do
      clock_out_time { Time.current }
    end

    factory :incomplete_sleep_record do
      clock_out_time { nil }
    end

    trait :completed do
      clock_out_time { Time.current }
    end
  end
end
