require 'rails_helper'

RSpec.describe Api::V1::SleepRecordsController, type: :controller do
  let(:user) { create(:user) }
  let(:serialized_response) do
    {
      'code' => 200,
      'status' => 'OK',
      'success' => true,
      'message' => a_hash_including(
        'data' => be_empty.or(
          a_collection_including(
            a_hash_including(
              'id' => kind_of(String),
              'type' => 'sleep_record',
              'attributes' => a_hash_including(
                'clock_in_time' => kind_of(String),
                'clock_out_time' => satisfy { |v| v.nil? || v.is_a?(String) },
                'duration_seconds' => kind_of(Integer),
                'user_id' => kind_of(Integer)
              )
            )
          )
        ),
        'pagination' => anything
      )
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

    context 'pagination' do
      before do
        create_list(:sleep_record, 5, user: user)
      end

      it 'returns paginated sleep records (page 1)' do
        get :index, params: { user_id: user.id, page: 1, per_page: 2 }
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        data = json_response['message']['data']
        pagination = json_response['message']['pagination']

        expect(data.size).to eq(2)
        expect(pagination['limit']).to eq(2)
        expect(pagination['page']).to eq(1)
      end

      it 'returns paginated sleep records (page 2)' do
        get :index, params: { user_id: user.id, page: 2, per_page: 2 }
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        data = json_response['message']['data']
        pagination = json_response['message']['pagination']

        expect(data.size).to eq(2)
        expect(pagination['limit']).to eq(2)
        expect(pagination['page']).to eq(2)
      end
    end
  end

  describe 'POST #clock_in' do
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

    it 'creates a new sleep record even if unclosed records exist (no longer closes them)' do
      # Create an old unclosed record
      old_unclosed = create(:sleep_record, user: user, clock_in_time: 2.hours.ago, clock_out_time: nil)

      travel_to(Time.current) do
        expect {
          post :clock_in, params: { user_id: user.id }
        }.to change(SleepRecord, :count).by(1)

        # old_unclosed remains unclosed because the logic is now in #clock_out
        old_unclosed.reload
        expect(old_unclosed.clock_out_time).to be_nil

        new_record = user.sleep_records.last
        expect(new_record.clock_in_time).to eq(Time.current)
        expect(new_record.clock_out_time).to be_nil
        expect(new_record.duration_seconds).to eq(0)

        expect(response).to have_http_status(:created)
      end
    end
  end

  describe 'POST #clock_out' do
    context 'with existing unclosed sleep record' do
      let(:fixed_time) { Time.zone.local(2024, 1, 1, 12, 0, 0) }

      let!(:unclosed_record) do
        travel_to(fixed_time - 2.hours) do
          create(:sleep_record, user: user, clock_in_time: Time.current, clock_out_time: nil)
        end
      end

      it 'closes existing record with correct duration' do
        travel_to(fixed_time) do
          expect {
            post :clock_out, params: { user_id: user.id }
          }.not_to change(SleepRecord, :count)  # Just closes, doesn't create

          unclosed_record.reload
          expect(unclosed_record.clock_out_time).to be_within(1.second).of(fixed_time)
          # 2 hours difference
          expect(unclosed_record.duration_seconds).to be_within(1).of(2.hours.to_i)

          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'with multiple unclosed records' do
      let!(:old_unclosed) { create(:sleep_record, user: user, clock_in_time: 3.hours.ago, clock_out_time: nil) }
      let!(:recent_unclosed) { create(:sleep_record, user: user, clock_in_time: 1.hour.ago, clock_out_time: nil) }

      it 'closes all unclosed records' do
        travel_to(Time.current) do
          expect {
            post :clock_out, params: { user_id: user.id }
          }.not_to change(SleepRecord, :count)

          [old_unclosed, recent_unclosed].each do |record|
            record.reload
            expect(record.clock_out_time).to eq(Time.current)
            expect(record.duration_seconds).to be_positive
          end

          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'without any unclosed sleep records' do
      it 'returns success and empty records' do
        post :clock_out, params: { user_id: user.id }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']['data']).to eq([])
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
