# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:sleep_records).dependent(:destroy) }
    it { should have_many(:following_users).class_name('Follow').with_foreign_key('follower_id') }
    it { should have_many(:followings).through(:following_users).source(:followed) }
    it { should have_many(:followed_users).class_name('Follow').with_foreign_key('followed_id') }
    it { should have_many(:followers).through(:followed_users) }
  end

  describe 'following methods' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    describe '#follow' do
      it 'follows another user successfully' do
        expect(user1.follow(user2)).to be_truthy
        expect(user1.following?(user2)).to be true
      end

      it 'cannot follow self' do
        expect(user1.follow(user1)).to be false
        expect(user1.following?(user1)).to be false
      end

      it 'cannot follow same user twice' do
        user1.follow(user2)
        expect(user1.followings.count).to eq(1)
        user1.follow(user2)
        expect(user1.followings.count).to eq(1)
      end
    end

    describe '#unfollow' do
      before { user1.follow(user2) }

      it 'unfollows a user successfully' do
        user1.unfollow(user2)
        expect(user1.following?(user2)).to be false
      end
    end

    describe '#following?' do
      it 'returns true when following the user' do
        user1.follow(user2)
        expect(user1.following?(user2)).to be true
      end

      it 'returns false when not following the user' do
        expect(user1.following?(user2)).to be false
      end
    end
  end
end
