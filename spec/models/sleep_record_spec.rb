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
  end
end
