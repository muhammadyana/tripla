require 'rails_helper'

RSpec.describe Api::V1::SleepRecordsController, type: :controller do
  let(:user) { create(:user) }
  let(:serialized_response) do
    {
      'code' => 200,
      'status' => 'OK',
      'success' => true,
      'message' => {
        'data' => [
          {
            'id' => '1',
            'type' => 'sleep_record',
            'attributes' => hash_including(
              'clock_in_time' => kind_of(String),
              'clock_out_time' => satisfy { |v| v.nil? || v.is_a?(String) },
              'duration_seconds' => kind_of(Integer),
              'user_id' => kind_of(Integer)
            )
          }
        ]
      }
    }
  end

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    let!(:sleep_record) { create(:sleep_record, user: user) }

    it 'returns cached sleep records' do
      expect(Rails.cache).to receive(:fetch)
        .with("user_sleep_records_#{user.id}", expires_in: 1.hour)
        .and_return(user.sleep_records)

      get :index, params: { user_id: user.id }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['code']).to eq(200)
      expect(json_response['status']).to eq('OK')
      expect(json_response['success']).to be true
      expect(json_response['message']['data']).to be_present
      expect(json_response['message']['data'].first['id']).to eq(sleep_record.id.to_s)
    end

    it 'returns fresh sleep records when cache expires' do
      Rails.cache.clear
      get :index, params: { user_id: user.id }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to match(serialized_response)
    end
  end

  describe 'POST #clock_in' do
    context 'with existing unclosed sleep record' do
      let(:fixed_time) { Time.zone.local(2024, 1, 1, 12, 0, 0) }

      let!(:unclosed_record) do
        travel_to(fixed_time - 2.hours) do
          create(:sleep_record,
            user: user,
            clock_in_time: Time.current,
            clock_out_time: nil
          )
        end
      end

      it 'closes existing record with correct duration and creates new one' do
        travel_to(fixed_time) do
          expect {
            post :clock_in, params: { user_id: user.id }
          }.to change(SleepRecord, :count).by(1)

          unclosed_record.reload
          expect(unclosed_record.clock_out_time).to be_within(1.second).of(fixed_time)
          expect(unclosed_record.duration_seconds).to be_within(1).of(2.hours.to_i)

          new_record = user.sleep_records.order(created_at: :desc).first
          expect(new_record.clock_in_time).to be_within(1.second).of(fixed_time)
          expect(new_record.clock_out_time).to be_nil
          expect(new_record.duration_seconds).to eq(0)

          expect(response).to have_http_status(:created)
        end
      end
    end

    context 'with multiple unclosed records' do
      let!(:old_unclosed) { create(:sleep_record, user: user, clock_in_time: 3.hours.ago, clock_out_time: nil) }
      let!(:recent_unclosed) { create(:sleep_record, user: user, clock_in_time: 1.hour.ago, clock_out_time: nil) }

      it 'closes all unclosed records and creates new one' do
        travel_to(Time.current) do
          expect {
            post :clock_in, params: { user_id: user.id }
          }.to change(SleepRecord, :count).by(1)

          [ old_unclosed, recent_unclosed ].each do |record|
            record.reload
            expect(record.clock_out_time).to eq(Time.current)
            expect(record.duration_seconds).to be_positive
          end
        end
      end
    end

    it 'creates a new sleep record when no unclosed records exist' do
      travel_to(Time.current) do
        expect {
          post :clock_in, params: { user_id: user.id }
        }.to change(SleepRecord, :count).by(1)

        new_record = user.sleep_records.last
        expect(new_record.clock_in_time).to eq(Time.current)
        expect(new_record.clock_out_time).to be_nil
        expect(new_record.duration_seconds).to eq(0)

        expect(response).to have_http_status(:created)
      end
    end
  end

  describe 'GET #following_sleep_records' do
    let(:followed_user) { create(:user) }
    let!(:sleep_record) { create(:completed_sleep_record, user: followed_user, clock_in_time: 1.day.ago) }

    before do
      create(:follow, follower: user, followed: followed_user)
    end

    it 'returns cached following sleep records' do
      expect(Rails.cache).to receive(:fetch)
        .with("following_sleep_records_#{user.id}", expires_in: 1.hour)
        .and_return(SleepRecord.all)

      get :following_sleep_records, params: { user_id: user.id }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['code']).to eq(200)
      expect(json_response['status']).to eq('OK')
      expect(json_response['success']).to be true
      expect(json_response['message']['data']).to be_present
    end

    it 'returns fresh following sleep records when cache expires' do
      Rails.cache.clear
      get :following_sleep_records, params: { user_id: user.id }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to match(serialized_response)
    end
  end
end
