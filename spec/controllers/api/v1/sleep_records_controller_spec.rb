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
      let!(:unclosed_record) { create(:sleep_record, user: user, clock_out_time: nil) }

      it 'closes existing record and creates new one' do
        expect {
          post :clock_in, params: { user_id: user.id }
        }.to change(SleepRecord, :count).by(1)

        expect(unclosed_record.reload.clock_out_time).not_to be_nil
        expect(response).to have_http_status(:created)
      end
    end

    it 'creates a new sleep record when no unclosed records exist' do
      expect {
        post :clock_in, params: { user_id: user.id }
      }.to change(SleepRecord, :count).by(1)

      expect(response).to have_http_status(:created)
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
