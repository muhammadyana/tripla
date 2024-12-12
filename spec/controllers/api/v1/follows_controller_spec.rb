require 'rails_helper'

RSpec.describe Api::V1::FollowsController, type: :controller do
  let(:user) { create(:user) }
  let(:target_user) { create(:user) }

  describe 'POST #follow' do
    context 'with valid parameters' do
      it 'follows a new user successfully' do
        post :follow, params: { user_id: user.id, target_user_id: target_user.id }

        expect(response).to have_http_status(:created)
        expect(user.following?(target_user)).to be true
      end

      it 'returns conflict when already following' do
        user.follow(target_user)

        post :follow, params: { user_id: user.id, target_user_id: target_user.id }

        expect(response).to have_http_status(:conflict)
      end

      it 'prevents self-following' do
        post :follow, params: { user_id: user.id, target_user_id: user.id }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when user does not exist' do
        post :follow, params: { user_id: 999999, target_user_id: target_user.id }
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error when target user does not exist' do
        post :follow, params: { user_id: user.id, target_user_id: 999999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #unfollow' do
    context 'with valid parameters' do
      before { user.follow(target_user) }

      it 'unfollows successfully' do
        post :unfollow, params: { user_id: user.id, target_user_id: target_user.id }

        expect(response).to have_http_status(:ok)
        expect(user.following?(target_user)).to be false
      end
    end

    context 'when not following' do
      it 'returns not found error' do
        post :unfollow, params: { user_id: user.id, target_user_id: target_user.id }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
