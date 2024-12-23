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
require 'rails_helper'

RSpec.describe SleepRecord, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:clock_in_time) }
  end

  describe 'callbacks' do
    context 'when calculating duration' do
      it 'sets duration_seconds before save' do
        sleep_record = build(:completed_sleep_record)
        sleep_record.save
        expected_duration = (sleep_record.clock_out_time - sleep_record.clock_in_time).to_i
        expect(sleep_record.duration_seconds).to eq(expected_duration)
      end

      it 'does not calculate duration without clock_out_time' do
        sleep_record = create(:incomplete_sleep_record)
        expect(sleep_record.duration_seconds).to eq(0)
      end
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let!(:this_week_record) { create(:completed_sleep_record, user: user, clock_in_time: Time.current) }
    let!(:last_week_record) { create(:completed_sleep_record, user: user, clock_in_time: 1.week.ago) }
    let!(:incomplete_record) { create(:incomplete_sleep_record, user: user) }

    describe '.for_week' do
      it 'returns records for the current week' do
        expect(SleepRecord.for_week).to include(this_week_record)
        expect(SleepRecord.for_week).not_to include(last_week_record)
      end

      it 'returns records for a specific week' do
        expect(SleepRecord.for_week(1.week.ago)).to include(last_week_record)
        expect(SleepRecord.for_week(1.week.ago)).not_to include(this_week_record)
      end
    end

    describe '.completed' do
      it 'returns only records with clock_out_time' do
        expect(SleepRecord.completed).to include(this_week_record, last_week_record)
        expect(SleepRecord.completed).not_to include(incomplete_record)
      end
    end

    describe '.following_records' do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:user3) { create(:user) }

      before do
        user1.follow(user2)

        @followed_complete = create(:completed_sleep_record,
          user: user2,
          clock_in_time: Time.current,
          clock_out_time: Time.current + 8.hours,
          duration_seconds: 8.hours.to_i
        )
        @followed_incomplete = create(:incomplete_sleep_record,
          user: user2,
          clock_in_time: Time.current
        )
        @followed_old = create(:completed_sleep_record,
          user: user2,
          clock_in_time: 2.weeks.ago
        )

        @not_followed = create(:completed_sleep_record,
          user: user3,
          clock_in_time: Time.current
        )
      end

      it 'orders by duration_seconds desc' do
        short_record = create(:completed_sleep_record,
          user: user2,
          clock_in_time: Time.current,
          clock_out_time: Time.current + 6.hours,
          duration_seconds: 6.hours.to_i
        )

        results = SleepRecord.following_records(user1).to_a
        expect(results.first.duration_seconds).to be > results.last.duration_seconds
        expect(results.first).to eq(@followed_complete)
        expect(results.last).to eq(short_record)
      end
    end

    describe '.clock_out_all' do
      let(:user) { create(:user) }
      let!(:unclosed_record) { create(:incomplete_sleep_record, user: user, clock_in_time: 2.hours.ago) }
      let!(:closed_record) { create(:completed_sleep_record, user: user) }

      it 'closes all uncompleted records' do
        travel_to(Time.current) do
          SleepRecord.clock_out_all
          unclosed_record.reload

          expect(unclosed_record.clock_out_time).to eq(Time.current)
          # Allow 1 second difference
          expect(unclosed_record.duration_seconds).to be_within(1).of(2.hours.to_i)
        end
      end

      it 'does not affect already closed records' do
        original_clock_out = closed_record.clock_out_time
        SleepRecord.clock_out_all

        expect(closed_record.reload.clock_out_time).to eq(original_clock_out)
      end
    end
  end
end
